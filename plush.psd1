@{
  RootModule           = 'plush.psm1'
  ModuleVersion        = '0.1.0'
  GUID                 = '37fd22bc-d322-4cba-af52-5f84c9d645e9'
  Author               = 'Jannchie'
  Description          = 'Prompt and line editing for PowerShell: prefix history search, inline history suggestions, menu completion, and a prompt drawn without spawning a process.'
  PowerShellVersion    = '5.1'
  CompatiblePSEditions = @('Desktop', 'Core')
  FunctionsToExport    = @('Enable-Plush')
  CmdletsToExport      = @()
  VariablesToExport    = @()
  AliasesToExport      = @()
}
