echo off
set working_dir=%cd%

echo "Install Electronite Build tools"

echo "%date% - %time%" > start_time_configure.txt

echo "Installing VS 2019 Community"
vs_community_2019.exe ^
	--wait --quiet --norestart ^
	--installWhileDownloading ^
	--add Microsoft.VisualStudio.Workload.NativeDesktop ^
	--add Microsoft.VisualStudio.Component.VC.ATLMFC ^
	--add Microsoft.VisualStudio.Component.VC.Tools.ARM64 ^
	--add Microsoft.VisualStudio.Component.VC.MFC.ARM64 ^
	--includeRecommended

echo "Installing WinSDK"
winsdksetup_10.0.20348.0.exe /features + /q /norestart

echo "Setting up Python 2.7.18"
msiexec /log python27_install.log /i python-2.7.18.amd64.msi /qn ALL=1 TARGETDIR=c:\python27 ALLUSERS=1
mklink c:\python27\python2.exe c:\python27\python.exe

echo "Setting up Python 3.11.1"
python-3.11.1-amd64.exe /quiet TargetDir=c:\python311 InstallAllUsers=1 PrependPath=1 Include_test=0
mklink c:\python311\python3.exe c:\python311\python.exe

Git-2.39.0-64-bit.exe /VERYSILENT /NORESTART

set Path=%Path%;C:\python27\Scripts;C:\python27;C:\python311\Scripts;C:\python311;C:\Program Files\Git\cmd
git config --system core.longpaths true
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

echo "Install node"
msiexec /i node-v16.19.0-x64.msi /log node_install.log /qn 

echo "Install chrome build tools"
set dest_dir=%HOMEDRIVE%%HOMEPATH%\Develop\Build-Electronite
md %dest_dir%
cd %dest_dir%
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git


echo "Restore initial directory
cd %working_dir%

echo "%date% - %time%" > end_time_configure.txt

