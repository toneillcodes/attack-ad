# Forest Functional Level
A breakdown of the common forest functional levels and their corresponding Windows Server versions (based on msDS-Behavior-Version values):
- 0: Windows 2000 (mixed/native)
- 1: Windows Server 2003 interim
- 2: Windows Server 2003
- 3: Windows Server 2008
- 4: Windows Server 2008 R2
- 5: Windows Server 2012
- 6: Windows Server 2012 R2
- 7: Windows Server 2016

Note: there are no new forest functional levels associated with Windows Server 2019 or Windows Server 2022.  
If you introduce DCs running these newer OS versions into a forest at FFL 7 (Windows Server 2016), they will still operate at the Windows Server 2016 functional level.  
This is because no new Active Directory features were introduced in those Windows Server versions that required a new functional level.
