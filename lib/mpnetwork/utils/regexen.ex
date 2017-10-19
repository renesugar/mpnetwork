defmodule Mpnetwork.Utils.Regexen do

  # taken from http://www.regular-expressions.info/email.html
  # Added A-Z to char classes to avoid having to use /i switch
  @email_regex ~r/
    \A(?=[A-Za-z0-9@.!#$%&'*+\/=?^_`{|}~-]{6,254}\z)
    (?=[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]{1,64}@)
    [A-Za-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+\/=?^_`{|}~-]+)*
    @ (?:(?=[A-Za-z0-9-]{1,63}\.)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+
    (?=[A-Za-z0-9-]{1,63}\z)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\z
  /x
  def email_regex, do: @email_regex

  # taken from... a bunch of sources and rfc's.
  @uri_regex ~r/^
    (?<scheme>
      \b
        (?> https? | mailto | [st]?ftp | aaas? | about | a?cap | cid | crid | data | dav | dict | dns | fax | file | geo | gopher | go | h323 | iax | icap | im | imap | info | ipp | iris | ldap | msrps? | news | nfs | nntp | pop | rsync | rtsp | sips? | sms | snmp | tag | telnet | tel | tip | tv | urn | uuid | view\-source | wss? | xmpp | aim | apt | afp | bitcoin | bolo | callto | chrome | content | cvs | doi | facetime | feed | finger | fish | git | gg | gizmoproject | gtalk | irc[s6]? | itms | jar | javascript | lastfm | ldaps | magnet | maps | market | message | mms | msnim | mumble | mvn | notes | palm | paparazzi | platform | proxy | psyc | query | rmi | rtmp | secondlife | sgn | skype | spotify | ssh | smb | soldat | steam | svn | teamspeak | things | udp | unreal | ventrilo | webcal | wtai | wyciwyg | xfire | xri | ymsgr)
      \b
      \:
    ){0}
    (?<scheme_separator>
      \/{0,3}
    ){0}
    (?<scheme_prefix>
      \g<scheme>
      \g<scheme_separator>
    ){0}
    (?<tld>
      \b
        (?> COM | ORG | EDU | GOV | UK | NET | CA | DE | JP | FR | AERO | ARPA | ASIA | A[UCDEFGILMNOQRSTWXZ] | US | RU | CH | IT | NL | SE | NO | ES | MIL | BIZ | B[ABDEFGHIJMNORSTVWYZ]R? | CAT | COOP | C[CDFGIKLMNORUVWXYZ] | D[JKMOZ] | E[CEGRTU] | F[IJKMO] | G[ABDEFGHILMNPQRSTUWY] | H[KMNRTU] | INFO | INT | I[DELMNOQRS] | JOBS | J[EMO] | K[EGHIMNPRWYZ] | L[ABCIKRSTUVY] | MOBI | MUSEUM | M[ACDEGHKLMNOPQRSTUVWXYZ] | NAME | N[ACEFGIPRUZ] | OM | PRO | P[AEFGHKLMNRSTWY] | QA | R[EOSW] | S[ABCDGHIJKLMNORTUVXYZ] | TRAVEL | TEL | TLD | T[CDFGHJKLMNOPRTVWZ] | U[AGYZ] | VET | V[ACEGINU] | WIKI | W[FS] | XN\-\- (?> 0ZWM56D | 11B5BS3A9AJ6G | 3E0B707E | 45BRJ9C | 80AKHBYKNJ4F | 80AO21A | 90A3AC | 9T4B11YI5A | CLCHC0EA0B2G2A9GCD | DEBA0AD | FIQS8S | FIQZ9S | FPCRJ9C3D | FZC2C9E2C | G6W251D | GECRJ9C | H2BRJ9C | HGBK6AJ7F53BBA | HLCJ6AYA9ESC7A | J6W193G | JXALPDLP | KGBECHTV | KPRW13D | KPRY57D | LGBBAT1AD8J | MGBAAM7A8H | MGBAYH7GPA | MGBBH1A71E | MGBC0A9AZCG | MGBERP4A5D4AR | O3CW4H | OGBPF8FL | P1AI | PGBS0DH | S9BRJ9C | WGBH1C | WGBL6A | XKC2AL3HYE2A | XKC2DL3A5EE0H | YFRO4I67O | YGBI2AMMX | ZCKZAH ) | XXX | Y[ET] | Z[AMW] )
      \b
    ){0}
    (?<ccsld>
      \g<tld>(?= [.]\g<tld>)
    ){0}
    (?<tlds>
      (?: [.]\g<ccsld>)? [.]\g<tld>
    ){0}
    (?<unicode_letter_number>
      (?!\.)[\pL\pN]
    ){0}
    (?<unicode_letter_number_other>
      (?!\.)[\pL&\pN\pCs\pSo]
    ){0}
    (?<allowed_name>
      \b(?:(?:\g<unicode_letter_number_other>\-\g<unicode_letter_number_other>)|\g<unicode_letter_number_other>){1,40}\b
    ){0}
    (?<subdomain_with_implicit_scheme>
      (?> w{2,3}\d{0,3} | mail | proxy | s[fm]tp | pop | ftp | irc | images | news | video )
      (?! \g<tlds> )
    ){0}
    (?<subdomain>
      (?! \g<subdomains_with_implicit_scheme> )
      \g<allowed_name>
      (?! \g<tlds> )
    ){0}
    (?<subdomains_with_implicit_scheme>
      \g<subdomain_with_implicit_scheme>(?: [.]\g<subdomain>){0,3}[.]
    ){0}
    (?<subdomains>
      \g<subdomain>(?: [.]\g<subdomain>){0,3}[.]
    ){0}
    (?<domain>
      \g<allowed_name>
      (?= \g<tlds> )
    ){0}
    (?<port>
      \d{1,5}
    ){0}
    (?<ipv4>
      ((25[0-5]|2[0-4][0-9]|[01]{0,1}[0-9][0-9]{0,1})\.){3,3}(25[0-5]|2[0-4][0-9]|[01]{0,1}[0-9][0-9]{0,1})
    ){0}
    (?<ipv6>
      (?:(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){6})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:::(?:(?:(?:[0-9a-fA-F]{1,4})):){5})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){4})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,1}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){3})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,2}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){2})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,3}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:[0-9a-fA-F]{1,4})):)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,4}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,5}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,6}(?:(?:[0-9a-fA-F]{1,4})))?::))))
    ){0}
    (?<hostname>
      (?: \g<subdomains>? \g<domain> \g<tlds>
        | \g<ipv4>
        | \g<ipv6>
      )
    ){0}
    (?<hostname_with_implicit_scheme>
      \g<subdomains_with_implicit_scheme> \g<domain> \g<tlds>
    ){0}
    (?<host>
      \g<hostname>
      (?: \:\g<port>)?
    ){0}
    (?<host_with_implicit_scheme>
      \g<hostname_with_implicit_scheme>
      (?: \:\g<port>)?
    ){0}
    (?<username>
      [\.\-\pL\pN]{2,40}
    ){0}
    (?<password>
      [\pL\pN\,\.\<\>\;\'\"\\\[\]\{\}\|\`\~\!\?\#\$\%\^\&\*\(\)\-\=\_\+]{1,50}
    ){0}
    (?<userinfo>
      (?: \g<username>(?: \: \g<password> )? \@ )
    ){0}
    (?<authority>
      \g<userinfo>? \g<host>
    ){0}
    (?<authority_with_implicit_scheme>
      \g<userinfo>? \g<host_with_implicit_scheme>
    ){0}
    (?<hex>
      [0-9a-f]
    ){0}
    (?<disallowed_encoded>
      \%[01][0-9A-F]
    ){0}
    (?<hex_encoded>
      (?! \g<disallowed_encoded> )
      \%\g<hex>{2}
    ){0}
    (?<html_entity>
      \& (?> \#[0-9]{1,4} | \#x\g<hex>{1,4} | [a-z]{2,8} )\;
    ){0}
    (?<path_segment>
      (?: (?:(?!\&)[\pL&\pCs\pN\-\_\$\.\+\*\'\(\)\,\:\;\~\@]) | \#(?=\pL) | \g<hex_encoded> | \g<html_entity> ){1,200}
    ){0}
    (?<path>
      (?: \/ \g<path_segment>? ){0,10} \#?
    ){0}
    (?<fragment>
      \# \g<path_segment>
    ){0}
    (?<querystring_name>
      \g<path_segment> (?: \[ \g<path_segment> \] )?
    ){0}
    (?<querystring_value>
      \g<path_segment>
    ){0}
    (?<name_value_pair>
      \g<querystring_name> (?: = \g<querystring_value> )?
    ){0}
    (?<name_value_pairs>
      \g<name_value_pair> (?: \& \g<name_value_pair>){0,20}
    ){0}
    (?<query>
      \? \g<name_value_pairs>?
    ){0}
    (?<locator>
      \g<path>? \g<query>? \g<fragment>?
    ){0}
    (?<URI>
      (?>
        \g<scheme_prefix> \g<authority>
      |
        \g<scheme_prefix>? \g<authority_with_implicit_scheme>
      )
      \g<locator>
    ){0}
    \g<URI>
  $/ix

  def uri_regex, do: @uri_regex
  def url_regex, do: @uri_regex

end
