defmodule MpnetworkWeb.ListingController do
  use MpnetworkWeb, :controller

  require Logger

  alias Mpnetwork.{Realtor, Listing, ClientEmail, Repo, Mailer, Permissions}
  # alias Mpnetwork.Realtor.Office
  alias Mpnetwork.Listing.AttachmentMetadata

  import Listing,
    only: [public_client_full_code: 1, public_broker_full_code: 1, public_customer_full_code: 1]

  plug(
    :put_layout,
    "public_listing.html" when action in [:client_full, :broker_full, :customer_full]
  )

  def search_help(conn, _params) do
    render(conn, "search_help.html")
  end

  # I wrote this function because String.to_integer puked sometimes
  # with certain spurious inputs and caused 500 errors.
  # Should probably be moved to a lib at some point.
  # This function is currently copied from attachment_controller.ex
  @filter_nondecimal ~r/[^0-9]+/
  defp unerring_string_to_int(bin) when is_binary(bin) do
    bin = Regex.replace(@filter_nondecimal, bin, "")

    case bin do
      "" -> nil
      val -> String.to_integer(val)
    end
  end

  defp unerring_string_to_int(n) when is_float(n), do: round(n)
  defp unerring_string_to_int(n) when is_integer(n), do: n
  defp unerring_string_to_int(_), do: nil

  def index(conn, %{"q" => query, "limit" => max} = _params) do
    max = case max do
      "" -> 50
      nil -> 50
      50 -> 50
      "50" -> 50
      100 -> 100
      "100" -> 100
      200 -> 200
      "200" -> 200
      500 -> 500
      "500" -> 500
      n -> unerring_string_to_int(n) || 1000
    end
    {total, listings, errors} = Realtor.query_listings(query, max, current_user(conn))
    primaries = Listing.primary_images_for_listings(listings)

    render(
      conn,
      "search_results.html",
      listings: listings,
      primaries: primaries,
      errors: errors,
      total: total,
      max: max
    )
  end

  # Round Robin landing view
  def index(conn, _params) do
    listings = Realtor.list_latest_listings_excluding_new(nil, 20)
    primaries = Listing.primary_images_for_listings(listings, AttachmentMetadata)
    # draft_listings = Realtor.list_latest_draft_listings(conn.assigns.current_user)
    # draft_primaries = Listing.primary_images_for_listings(draft_listings, AttachmentMetadata)
    upcoming_broker_oh_listings = Realtor.list_next_broker_oh_listings(nil, 30)

    upcoming_broker_oh_primaries =
      Listing.primary_images_for_listings(upcoming_broker_oh_listings, AttachmentMetadata)

    upcoming_cust_oh_listings = Realtor.list_next_cust_oh_listings(nil, 30)

    upcoming_cust_oh_primaries =
      Listing.primary_images_for_listings(upcoming_cust_oh_listings, AttachmentMetadata)

    render(
      conn,
      "index.html",
      listings: listings,
      primaries: primaries,
      upcoming_broker_oh_listings: upcoming_broker_oh_listings,
      upcoming_broker_oh_primaries: upcoming_broker_oh_primaries,
      upcoming_cust_oh_listings: upcoming_cust_oh_listings,
      upcoming_cust_oh_primaries: upcoming_cust_oh_primaries
    )
  end

  def inspection_sheet(conn, _params) do
    upcoming_broker_oh_listings = Realtor.list_next_broker_oh_listings(nil, 30)
    upcoming_cust_oh_listings = Realtor.list_next_cust_oh_listings(nil, 30)

    render(
      conn,
      "inspection_sheet.html",
      upcoming_broker_oh_listings: upcoming_broker_oh_listings,
      upcoming_cust_oh_listings: upcoming_cust_oh_listings
    )
  end

  def new(conn, _params) do
    if !Permissions.read_only?(current_user(conn)) do
      changeset =
        Realtor.change_listing(%Mpnetwork.Realtor.Listing{
          user_id: current_user(conn).id,
          broker_id: conn.assigns.current_office && conn.assigns.current_office.id
        })

      render(
        conn,
        "new.html",
        changeset: changeset,
        offices: offices(),
        users: users(conn.assigns.current_office, conn.assigns.current_user)
      )
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def create(conn, %{"listing" => listing_params}) do
    if !Permissions.read_only?(current_user(conn)) do
      # inject current_user.id and current_office.id (as broker_id)
      listing_params = Enum.into(%{"broker_id" => conn.assigns.current_office.id}, listing_params)
      listing_params = filter_empty_ext_urls(listing_params)

      case Realtor.create_listing(listing_params) do
        {:ok, listing} ->
          conn
          |> put_flash(:info, "Listing created successfully.")
          |> redirect(to: listing_path(conn, :show, listing))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(
            conn,
            "new.html",
            changeset: changeset,
            offices: offices(),
            users: users(conn.assigns.current_office, conn.assigns.current_user)
          )
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def show(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id) |> Repo.preload([:user, :broker, :colisting_agent])
    broker = listing.broker
    agent = listing.user
    colisting_agent = listing.colisting_agent
    attachments = Listing.list_attachments(id, AttachmentMetadata)

    render(
      conn,
      "show.html",
      listing: listing,
      broker: broker,
      agent: agent,
      colisting_agent: colisting_agent,
      attachments: attachments
    )
  end

  def edit(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        attachments = Listing.list_attachments(listing.id, AttachmentMetadata)
        changeset = Realtor.change_listing(listing)

        render(
          conn,
          "edit.html",
          listing: listing,
          attachments: attachments,
          changeset: changeset,
          broker: listing.broker,
          offices: offices(),
          users: users(conn.assigns.current_office, conn.assigns.current_user)
        )
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  # def edit_mls(conn, %{"id" => id}) do
  #   listing = Realtor.get_listing!(id)
  #   ensure_owner_or_admin(conn, listing, fn ->
  #     attachments = Listing.list_attachments(listing.id)
  #     changeset = Realtor.change_listing(listing)
  #     render(conn, "edit_mls.html",
  #       listing: listing,
  #       attachments: attachments,
  #       changeset: changeset,
  #       offices: offices(),
  #       users: users(conn.assigns.current_office, conn.assigns.current_user)
  #     )
  #   end)
  # end

  def update(conn, %{"id" => id, "listing" => listing_params}) do
    # IO.inspect listing_params, limit: :infinity
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)
      listing_params = filter_empty_ext_urls(listing_params)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        case Realtor.update_listing(listing, listing_params) do
          {:ok, listing} ->
            conn
            |> put_flash(:info, "Listing updated successfully.")
            |> redirect(to: listing_path(conn, :show, listing))

          {:error, %Ecto.Changeset{} = changeset} ->
            attachments = Listing.list_attachments(id, AttachmentMetadata)

            render(
              conn,
              "edit.html",
              listing: listing,
              attachments: attachments,
              changeset: changeset,
              offices: offices(),
              users: users(conn.assigns.current_office, conn.assigns.current_user)
            )
        end
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def delete(conn, %{"id" => id}) do
    if !Permissions.read_only?(current_user(conn)) do
      listing = Realtor.get_listing!(id)

      if Permissions.owner_or_admin_of_same_office_or_site_admin?(current_user(conn), listing) do
        {:ok, _listing} = Realtor.delete_listing(listing)

        conn
        |> put_flash(:info, "Listing deleted successfully.")
        |> redirect(to: listing_path(conn, :index))
      else
        send_resp(conn, 405, "Not allowed")
      end
    else
      send_resp(conn, 405, "Not allowed")
    end
  end

  def broker_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :broker)
  end

  def client_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :client)
  end

  def customer_full(conn, %{"id" => signature}) do
    _do_public_listing(conn, signature, :customer)
  end

  defp _do_public_listing(conn, signature, type_of_listing) do
    {decrypted_id, decrypted_expiration_date} =
      Listing.from_listing_code(signature, type_of_listing)

    listing =
      Realtor.get_listing!(decrypted_id) |> Repo.preload([:user, :broker, :colisting_agent])

    broker = listing.broker
    agent = listing.user
    co_agent = listing.colisting_agent
    id = listing.id
    %{^id => showcase_image} = Listing.primary_images_for_listings([listing], AttachmentMetadata)

    case DateTime.compare(decrypted_expiration_date, Timex.now()) do
      :gt ->
        render(
          conn,
          "#{type_of_listing}_full.html",
          listing: listing,
          broker: broker,
          agent: agent,
          co_agent: co_agent,
          showcase_image: showcase_image
        )

      _ ->
        # 410 is "Gone"
        send_resp(conn, 410, "Link has expired")
    end
  end

  def email_listing(conn, %{"id" => id}) do
    listing = Realtor.get_listing!(id)
    # if current_user(conn).id == listing.user_id || current_user(conn).role_id < 3 do
    render(conn, "email_listing.html", listing: listing)
    # else
    #   send_resp(conn, 405, "Not allowed to email a listing that is not yours")
    # end
  end

  def send_email(
        conn,
        %{
          "id" => id,
          "email" => %{
            "email_address" => email_address,
            "type" => type,
            "name" => name,
            "subject" => subject,
            "body" => body,
            "cc_self" => cc_self
          }
        } = _params
      )
      when type in ~w[broker client customer] do
    # checkboxes come in this way...
    cc_self = cc_self == "true"
    listing = Realtor.get_listing!(id) |> Repo.preload(:user)
    current_user = conn.assigns.current_user
    id = listing.id

    url =
      case type do
        "broker" ->
          public_broker_full_url(conn, :broker_full, public_broker_full_code(listing))

        "client" ->
          public_client_full_url(conn, :client_full, public_client_full_code(listing))

        "customer" ->
          public_customer_full_url(conn, :customer_full, public_customer_full_code(listing))

        _ ->
          raise "unknown public listing type: #{type}"
      end

    sent_email =
      ClientEmail.send_client(
        email_address,
        name,
        subject,
        body,
        current_user,
        listing,
        url,
        cc_self
      )

    {success, results} =
      case Mailer.deliver(sent_email) do
        {:ok, results} -> {true, results}
        {:error, :timeout} -> {false, :timeout}
        {:error, reason} -> {false, reason}
        unknown -> {false, unknown}
      end

    case {success, results} do
      {true, results} ->
        Logger.info(
          "Sent listing id #{id} of type #{type} to #{email_address}#{
            if cc_self, do: " (cc'ing self)", else: ""
          }, result: #{inspect(results)}"
        )

      {false, :timeout} ->
        Logger.info("TIMED OUT emailing listing id #{id} of type #{type} to #{email_address}")

      {false, reason} ->
        Logger.info("Error emailing listing id #{id}, reason given: #{inspect(reason)}")
    end

    conn =
      case {success, results} do
        {true, _} ->
          conn |> put_flash(:info, "Listing emailed to #{type} at #{email_address} successfully.")

        {false, :timeout} ->
          conn
          |> put_flash(
            :error,
            "ERROR: Trying to email this listing to #{type} at #{email_address} timed out for some reason. Please try again."
          )

        {false, reason} ->
          conn
          |> put_flash(
            :error,
            "ERROR: Problem encountered emailing to #{email_address}. Reason given: #{
              inspect(reason)
            }"
          )
      end

    redirect(conn, to: listing_path(conn, :show, id))
  end

  defp offices do
    Realtor.list_offices()
  end

  # defp users do
  #   Realtor.list_users
  # end

  defp users(office, current_user) do
    if Permissions.site_admin?(current_user) do
      Realtor.list_users()
    else
      Realtor.list_users(office)
    end
  end

  # defp ensure_owner_or_admin(conn, resource, lambda) do
  #   u = current_user(conn)
  #   oid = resource.user_id
  #   admin = u.role_id < 3
  #   if u.id == oid || admin do
  #     lambda.()
  #   else
  #     send_resp(conn, 405, "Not allowed")
  #   end
  # end

  defp filter_empty_ext_urls(listing_params) do
    if listing_params["ext_urls"] do
      %{"ext_urls" => ext_urls} = listing_params

      if ext_urls do
        ext_urls = Enum.filter(ext_urls, &(&1 != ""))
        Enum.into(%{"ext_urls" => ext_urls}, listing_params)
      else
        listing_params
      end
    else
      listing_params
    end
  end
end
