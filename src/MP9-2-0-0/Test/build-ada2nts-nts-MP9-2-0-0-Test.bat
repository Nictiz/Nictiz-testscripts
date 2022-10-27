@setlocal enableextensions
@echo off

echo ==ADA2NTS==
call ant -f _internalTools\ant-build\build-ada2nts-mp-920.xml >_internalTools\ant-build.log

echo ==NTS==
call build-nts-MP9-2-0-0-Test
call build-nts-MP9-2-0-0-MedMij-Test

pause