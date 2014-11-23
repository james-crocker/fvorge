# VIRuntime.pm is here ONLY TO SATISFY the unit tests. Assure that any
# packages which require VIRuntime use the installed VMware versions
# FIRST in @INC - otherwise they will surely fail.

# The *real* VMware::VIRuntime depends VILib.pm, VICommon.pm

package VMware::VIRuntime;
our $VERSION = '5.5.0';

1;
