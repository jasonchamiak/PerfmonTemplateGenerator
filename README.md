# PerfmonTemplateGenerator
This script can be run on any Windows 2008+ Server and will generate a perfmon template for you.

When executing this script, please be sure to supply the path and file name of the template you would like created. Be sure that the file extension is xml. Here is
an example.
.\CreatePerfmonTemplate.ps1 -filename C:\Temp\perfmon.xml
If no path is provided, the output will default to C:\perfmon_template.xml. After the template is created, you will need to create a new perfmon data collector set using your newly created perfmon template. The schedule and other details are already defined as part of the template.
