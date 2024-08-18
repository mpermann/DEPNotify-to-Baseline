# DEPNotify-to-Baseline

This guide will detail how to utilize [Baseline](https://github.com/SecondSonConsulting/Baseline) to provide the same functionality the Jamf [DEPNotify-Starter](https://github.com/jamf/DEPNotify-Starter) script provides. It is assumed you already have a working DEPNotify-Starter workflow currently in use with automated device enrollment. We'll utilize the existing Jamf Pro policies for the Baseline workflow.

You need to decide what kind of workflow you want to use for your Baseline deployment. You can choose to create and use a custom made, signed and notarized Baseline package or you can use the standard Baseline package. While there are many ways you can create a workflow, this guide will limit itself to the following two workflows:
1.	Baseline configuration delivered using a plist-based file which is part of a signed and notarized, custom Baseline installer package deployed in a PreStage Enrollment. Requires Apple Developer ID Installer signing certificate.
2.	Baseline configuration delivered using a configuration profile and the standard Baseline signed and notarized installer package deployed in a PreStage Enrollment. The branding logos, application and policy icons, end user license agreement file and registration script are deployed with an installer package delivered using a script and installer package both hosted on an https server. No Apple Developer ID Installer signing certificate needed for this workflow.

Please checkout the [Wiki](https://github.com/mpermann/DEPNotify-to-Baseline/wiki) for specifics on how to utilize this project.

https://github.com/user-attachments/assets/6cf3d39e-f7de-4432-b37d-c75ae000e12d
