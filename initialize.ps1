#Modified from Windows based images to run on Linux
#https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-express/start.ps1
#
# SA_PASSWORD = Default sa password (inherited from mssql image)
# ACCEPT_EULA = (inherited from mssql image)
# ENABLE_CLR = Y for enabling CLR
# MAX_MEMORY = Defines the max SQL Server memory
# SA_NO_POLICY_PASSWORD = Overrides the default SA_PASSWORD without any policy (useful for tests)
# AUTO_CLOSE = Defines AUTO_CLOSE ON or OFF (Default OFF)

Write-Output 'Configuring SQL Server'

$pwd = $env:SA_PASSWORD

if ('Y' -eq $env:ENABLE_CLR)
{
	$sqlcmd = ""
	$sqlcmd += "EXEC sp_configure 'show advanced options' , '1';"
	$sqlcmd += "RECONFIGURE;"

	Write-Output "sqlcmd -Q $($sqlcmd)"
	& sqlcmd -S 127.0.0.1 -U SA -P $pwd -Q $sqlcmd

	$sqlcmd = ""
	$sqlcmd += "EXEC sp_configure 'clr enabled' , '1'"
	$sqlcmd += "RECONFIGURE;"

	Write-Output "sqlcmd -Q $($sqlcmd)"
	& sqlcmd -S 127.0.0.1 -U SA -P $pwd -Q $sqlcmd
}

if ($null -ne $env:SA_NO_POLICY_PASSWORD)
{
	$sqlcmd = ""
	$sqlcmd += "ALTER LOGIN sa with password='" + $env:SA_NO_POLICY_PASSWORD + "',CHECK_EXPIRATION=OFF,CHECK_POLICY=OFF;"
	$sqlcmd += "ALTER LOGIN sa ENABLE;"
	
	Write-Output "sqlcmd -Q $($sqlcmd)"
	& sqlcmd -S 127.0.0.1 -U SA -P $pwd -Q $sqlcmd

	$pwd = $env:SA_NO_POLICY_PASSWORD
}

if ($null -ne $env:MAX_MEMORY)
{
	$sqlcmd = ""
	$sqlcmd += "EXEC sys.sp_configure N'max server memory (MB)', N'" + $env:MAX_MEMORY + "';";
	$sqlcmd += "RECONFIGURE;"
		
	Write-Output "sqlcmd -Q $($sqlcmd)"
	& sqlcmd -S 127.0.0.1 -U SA -P $pwd -Q $sqlcmd
}

if ($null -ne $env:ATTACH_PATH)
{
	if (Test-Path $env:ATTACH_PATH)
	{
		$configFiles = (Get-ChildItem -Path $env:ATTACH_PATH -Recurse -Filter *.json)
		foreach($configFile in $configFiles)
		{
			[string]$attach_dbs_cleaned = ($configFile | Get-Content -Raw)
			$attach_dbs_cleaned = $attach_dbs_cleaned.Replace('"','')
			$attach_dbs_cleaned = $attach_dbs_cleaned.TrimStart('\\').TrimEnd('\\')
			$dbs = ConvertFrom-Json $attach_dbs_cleaned

			if ($dbs -is [String])
			{
				Write-Error 'Invalid attach_dbs format'
			}
			elseif ($null -ne $dbs -And $dbs.Length -gt 0)
			{
				Foreach($db in $dbs) 
				{     
					$files = @();
					Foreach($file in $db.dbFiles)
					{
						$files += "(FILENAME = N'$($file)')";           
					}

					$files = $files -join ","
					$createdatabase = "CREATE DATABASE [$($db.dbName)] ON $($files) FOR ATTACH".Replace("'","''")
					$changedbowner = "ALTER DATABASE [$($db.dbName)] SET TRUSTWORTHY ON; USE [$($db.dbName)]; EXEC sp_changedbowner 'sa';".Replace("'","''")
					$autoclose = "ALTER DATABASE [$($db.dbName)] SET AUTO_CLOSE $env:AUTO_CLOSE WITH NO_WAIT".Replace("'","''")
				
					$sqlcmd = ""
					$sqlcmd += "IF NOT EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') "
					$sqlcmd += "BEGIN "
					$sqlcmd += "EXEC sp_executesql N'$($createdatabase)'; "
					$sqlcmd += "END; "
					$sqlcmd += "EXEC sp_executesql N'$($changedbowner)'; "
					$sqlcmd += "EXEC sp_executesql N'$($autoclose)'; "
					
					Write-Output "sqlcmd -Q $sqlcmd"
					& sqlcmd -S 127.0.0.1 -U SA -P $pwd -Q $sqlcmd					
				}
			}
		}
	}
}

Write-Output 'Configuration finalized'
