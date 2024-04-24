@echo off
rmdir /s /q "..\FOS_CODES/FOS_PROJECT_2024_template\obj"
chdir ..\bin

bash --login -c 'cd c:/FOS/FOS_CODES/FOS_PROJECT_2024_template; export PATH="c:\FOS\opt\cross\bin:$PATH"; make -j all;'
exit