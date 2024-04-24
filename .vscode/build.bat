@echo off
rmdir /s /q "..\FOS_CODES/FOS_Labs_Template\obj"
chdir ..\bin

bash --login -c 'cd c:/fos_cygwin/FOS_CODES/FOS_Labs_Template; export PATH="c:\fos_cygwin\opt\cross\bin:$PATH"; make -j all;'
exit