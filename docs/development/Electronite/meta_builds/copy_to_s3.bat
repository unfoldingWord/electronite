rem Copy electronite builds to S3 storage.  First do cd to build folder before running script. 
rem  Only parameter is version.  If AWS keys are not set, will do prompting.
rem
rem troubleshooting:
rem   Got an S3 error that AWS user did not exist when entering credentials at prompts.  
rem     No obvious reason for this, but found it started working by either setting or 
rem     clearing ID `export AWS_SECRET_ACCESS_KEY=` before running script.
rem
rem Example `.\copy_to_s3.bat v25.3.2 <key> <secret>`

SETLOCAL
set VERSION=%1
set KEY_ID=%2
set ACCESS_KEY=%3

echo "Copying Electronite builds for VERSION to S3"

rem set AWS Keys in environment variables
if NOT %KEY_ID%. == . (
  set AWS_ACCESS_KEY_ID=%KEY_ID%
)

if NOT %ACCESS_KEY%. == . (
  set AWS_SECRET_ACCESS_KEY=%ACCESS_KEY%
)

set TARGET=win

rem do the s3 copy commands and then exit bash
rem presumes to current folder is the build folder
aws s3 cp results\%TARGET%\%VERSION%\arm64\dist.zip s3://electronite-build-data/Electronite/%TARGET%/%VERSION%/arm64/dist.zip
aws s3 cp results\%TARGET%\%VERSION%\x86\dist.zip s3://electronite-build-data/Electronite/%TARGET%/%VERSION%/x86/dist.zip
aws s3 cp results\%TARGET%\%VERSION%\x64\dist.zip s3://electronite-build-data/Electronite/%TARGET%/%VERSION%/x64/dist.zip

if NOT %KEY_ID%. == . (
  echo "Clearing temp AWS_ACCESS_KEY_ID"
  set AWS_ACCESS_KEY_ID=
)

if NOT %ACCESS_KEY%. == . (
  echo "Clearing temp AWS_SECRET_ACCESS_KEY"
  set AWS_SECRET_ACCESS_KEY=
)

echo "All copies completed to %VERSION%"
