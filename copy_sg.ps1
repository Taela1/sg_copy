# Define working directory and path to exoscli // Arbeitsverzeichnis definieren sowi Pfad zur exocli
$outdir="e:\exocli\"
$exo="e:\exocli\exo.exe"

$execute = Read-Host -Prompt 'Do you want to export or import ?'

if (($execute =! "import") -or ($execute =! "export")) { write-host "can only import or export - exiting"; exit }

if ($execute = "export" ) {
  # Get existing SG names // Alle existierenden SGs auslesen
  $sg=$(& $exo compute security-group list -O json | ConvertFrom-Json)

  # Get rules for each SG and write to workdir // Für alle existierenden SGs das Regelwerk auslesen und als Datei in das Arbeitsverzeichnis schreiben
  foreach ($sgrule in $sg.name){ 
    & $exo compute security-group show $sgrule -O json > $outdir$sgrule.json
    }
  exit
}  

if ($execute = "import" ) {

  ## Import of SGs and rules // Import der SGs und des Regelwerkes
    
    $outfiles=get-childitem $outdir -Filter *.json
    foreach ($outfile in $outfiles) {
      $sgdetails=Get-Content $outdir$outfile | ConvertFrom-Json
      $descritpion=$sgdetails.description
      if (([string]::IsNullOrEmpty($description))) { $description = "empty" }
      $securitygroup=$sgdetails.name
      & $exo compute security-group add $sgdetails.name --description $description
      foreach ($rule in $sgdetails.ingress_rules){
        $ruledescription=$rule.description
        if (([string]::IsNullOrEmpty($ruledescription))) { $ruledescription = "empty" }
        $ruleprotocol=$rule.protocol
        $( if ($rule.security_group) {$rulesourceoption = "--security-group"} else {$rulesourceoption="--network"})
        $( if ($rule.security_group) {$rulesource = $rule.security_group} else {$rulesource = $rule.network})
        $rulestartport=$rule.start_port
        $ruleendport=$rule.end_port
        $ruleicmpcode=$rule.icmp_code
        $ruleicmptype=$rule.icmp_type
        if ($ruleprotocol -eq "icmp") {
          & $exo compute security-group rule add $securitygroup --description $ruledescription --flow ingress --protocol $ruleprotocol --icmp-code $ruleicmpcode --icmp-type $ruleicmptype $rulesourceoption $rulesource
          }
          elseif (($ruleprotocol -eq "esp") -or ($ruleprotocol -eq "ah") -or ($ruleprotocol -eq "gre") -or ($ruleprotocol -eq "ipip"))
          {
          & $exo compute security-group rule add $securitygroup --description $ruledescription --flow ingress --protocol $ruleprotocol $rulesourceoption $rulesource
          }
          else
          {
          & $exo compute security-group rule add $securitygroup --description $ruledescription --flow ingress --protocol $ruleprotocol --port $rulestartport-$ruleendport $rulesourceoption $rulesource
          }
      }
      foreach ($rule in $sgdetails.egress_rules){
        $ruledescription=$rule.description
        if (([string]::IsNullOrEmpty($ruledescription))) { $ruledescription = "empty" }
        $ruleprotocol=$rule.protocol
        $( if ($rule.security_group) {$rulesourceoption = "--security-group"} else {$rulesourceoption="--network"})
        $( if ($rule.security_group) {$rulesource = $rule.security_group} else {$rulesource = $rule.network})
        $rulestartport=$rule.start_port
        $ruleendport=$rule.end_port
        $ruleicmpcode=$rule.icmp_code
        $ruleicmptype=$rule.icmp_type
        if ($ruleprotocol -eq "icmp") {
          echo "& $exo compute security-group rule add $securitygroup --description $ruledescription --flow egress --protocol $ruleprotocol --icmp-code $ruleicmpcode --icmp-type $ruleicmptype $rulesourceoption $rulesource"
          }
          elseif (($ruleprotocol -eq "esp") -or ($ruleprotocol -eq "ah") -or ($ruleprotocol -eq "gre") -or ($ruleprotocol -eq "ipip"))
          {
          echo "& $exo compute security-group rule add $securitygroup --description $ruledescription --flow egress --protocol $ruleprotocol $rulesourceoption $rulesource"
          }
          else
          {
          echo "& $exo compute security-group rule add $securitygroup --description $ruledescription --flow egress --protocol $ruleprotocol --port $rulestartport-$ruleendport $rulesourceoption $rulesource"
          }
      }
    }
}