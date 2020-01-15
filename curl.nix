# curl --insecure -b tok -H "Prefer:odata.maxpagesize=1000" 'https://domain:maybePort/b1s/v1/UserQueries' > sql/UserQueries-sql.sql
with import <nixpkgs> {};
let
  curlCmd = "${curl}/bin/curl";
  serverUrl = "domain:maybePort";
  database = "something";

  _jq = "${jq}/bin/jq";
  _perl = "${perl}/bin/perl";
  _awk = "${gawk}/bin/awk";

  cmd = name: cd: 
    let der = writeShellScriptBin name cd;
    in { bin = "${der}/bin/${name}"; inherit der; };

  login = cmd "hsl-login" ''
    ${curlCmd} -X POST -c tok --insecure -d '{ "CompanyDB": "${database}", "UserName": "'$1'", "Password": "'$2'"  }' ${serverUrl}/Login 
  '';
  get = cmd "hsl-get" ''
    url="$1"; query="$2"; shift 2
    ${curlCmd} -G -b tok --insecure --data-urlencode "$query" --url "${serverUrl}/$url" "$@"
  '';
  update = cmd "hsl-update" ''
    url="$1"; data="$2"; shift 2
    ${curlCmd} --silent --show-error -X PATCH -b tok --insecure -H "Content-Type:application/json" --url "${serverUrl}/$url" --data "$data" "$@"
  '';
  commands = [
    login get update
  # curl --insecure -b tok 'https://domain:maybePort/b1s/v1/UserQueries(InternalKey=29,QueryCategory=3)'
  ( cmd "hsl-getUserQuery" ''${get.bin} "UserQueries(InternalKey=$1,QueryCategory=$2)" ""'' )
  ( cmd "hsl-updateUserQuery" ''
      key="$1"; category="$2"; json="$3"; shift 3
      ${update.bin} "UserQueries(InternalKey=$key,QueryCategory=$category)" "$json" "$@"
    '' )

  # hsl-getUserQueries '$select=InternalKey,QueryCategory,QueryDescription,Query&$filter=QueryCategory ge 18' -H 'Prefer:odata.maxpagesize=0' > work/UserQueries.json
  ( cmd "hsl-getUserQueries" ''${get.bin} UserQueries "$@"'' )
  ( cmd "hsl-getAllUserQueries" ''hsl-getUserQueries '$select=InternalKey,QueryCategory,QueryDescription,Query&$filter=QueryCategory ge 18' -H 'Prefer:odata.maxpagesize=0' '' )

  # hsl-userQueriesToTemplate work/UserQueries.json > work/UserQueries-work.sql
  ( cmd "hsl-userQueriesToTemplate" 
    ''
      ${_jq} -r '.value | .[] |
        [ "----::::", "Language:", "T-SQL",  "InternalKey:", .InternalKey,  "QueryCategory:", .QueryCategory,  "QueryDescription:", .QueryDescription, "::::----" ]
        ,[.Query]
        ,[] | @tsv' "$@" |
        ${ _perl } -pe 's/\\r/\n/g' | ${ _perl } -pe 's/\\t/\t/g'
    '' )

  ( cmd "hsl-userQueriesTemplateToJson" '' ${ _awk } -f template2json.awk | ${ _jq } -R -n -f template2json.jq '' )

  ( cmd "hsl-getAllUserQueriesTemplate" ''hsl-getAllUserQueries | hsl-userQueriesToTemplate'' )

  ( cmd "hsl-updateUserQueriesFiltered" # : UserQueriesTemplate -|> jqfilter -> JsonError option
    ''
      userQueries=$(  hsl-userQueriesTemplateToJson | jq -c '.[] | '"$1"' | del(.Language) ' )
      # Loop over lines.
      OLDIFS="$IFS"; IFS=$'\n'
      for userQuery in $userQueries
      do
          # Put query json fields into array
          declare -A myarray
          while IFS="=" read -r key value; do
              myarray["$key"]="$value"
          done < <(echo "$userQuery" | jq -r ' to_entries | .[] | .key + "=" + (.value | tostring) ' )
          queryData=$( echo "$userQuery" | jq -c ' .Query |= ( sub("\\\\t";"\t";"g") |  sub("\\\\r";"\r";"g") ) | del(.QueryCategory) | del(.InternalKey) ' )
          hsl-updateUserQuery "''${myarray[InternalKey]}" "''${myarray[QueryCategory]}" "$queryData" |
            ${_jq} --argjson q "$userQuery" '{response: . , userQuery: $q}' 1>&2
      done
      IFS="$OLDIFS"
    '' )

  # hsl-updateUserQueriesAll < work/UserQueries-work.sql
  ( cmd "hsl-updateUserQueriesAll" '' hsl-updateUserQueriesFiltered ' . ' '' )
  # hsl-updateUserQueryByKey 457 < work/UserQueries-work.sql
  ( cmd "hsl-updateUserQueryByKey" '' hsl-updateUserQueriesFiltered 'select(.InternalKey=='"$1"')' '' )
  # hsl-updateUserQueriesByCategory 18 < work/UserQueries-work.sql
  ( cmd "hsl-updateUserQueriesByCategory" '' hsl-updateUserQueriesFiltered 'select(.QueryCategory=='"$1"')' '' )

  # hsl-updateUserQueriesByLanguage HANA < work/UserQueries-work.sql
  ( cmd "hsl-updateUserQueriesByLanguage" '' hsl-updateUserQueriesFiltered 'select(.Language=="'"$1"'")' '' )

  ];
in
mkShell {
  buildInputs = [ figlet jq perl gawk ( map (c: c.der) commands ) ];

  shellHook = ''
    figlet 'Hana SL Commands'
    echo 'in order to login: hsl-login USERNAME PASSWORD'
    echo '* all requests after login will use tok file to autenticate' 
    echo 'in order to get: hsl-get RESOURCE_NAME' 

    # trap "echo 'cleaning up...';rm tok" EXIT
  '';
}
