
#!/bin/bash
##sed -i '1s/^.*#//;s/\r$//' changelog.sh
#git update-index --chmod=+x changelog.sh

#curversion=$( git describe --tags --always )
#curtag=$( git describe --tags --always --abbrev=0 )

lua Plater_ChangeLog.lua latest >> CHANGELOG.md
