# Copyright (c) 2013 SIOS Technology Corp.  All rights reserved.

# This file is part of FVORGE.

# FVORGE is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# FVORGE is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with FVORGE.  If not, see <http://www.gnu.org/licenses/>.

package OVF::Service::Locale::Vars;

use strict;
use warnings;

our %locale;
my %common;

$common{'RHEL'} = {
	'packages' => {
		'DE' => [ '"German Support"' ],
		'KR' => [ '"Korean Support"' ],
		'JP' => [ '"Japanese Support"' ]
	},
	'LANG' => {
		'EN' => 'en_US.UTF-8',
		'DE' => 'de_DE.UTF-8',
		'KR' => 'ko_KR.UTF-8',
		'JP' => 'ja_JP.UTF-8'
	},
	'default' => 'EN',
	'files'   => {
		'language' => {
			path  => '/etc/sysconfig/i18n',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{LANG="<LOCALE_LANG>"
SYSFONT="latarcyrheb-sun16"}
				}
			}
		},
		'bash_profile' => {
			path  => '/root/.bash_profile',
			save  => 'once',
			chmod => 644,
			apply => {
				1 => {
					tail    => 1,
					content => q{export LANG="<LOCALE_LANG>"
export LANGUAGE="<LOCALE_LANG>"}
				}
			}
		}
	}
};

$common{'SLES'} = {
	'LANG' => {
		'EN' => 'en_US.UTF-8',
		'DE' => 'de_DE.UTF-8',
		'KR' => 'ko_KR.UTF-8',
		'JP' => 'ja_JP.UTF-8'
	},
	'yastLang' => {
		'EN' => 'en_US',
		'DE' => 'de_DE',
		'KR' => 'ko_KR',
		'JP' => 'ja_JP'
	},
	'default' => 'EN',
	'files'   => {
		'bash_profile' => {
			path  => '/root/.bash_profile',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					tail    => 1,
					content => q{export LANG="<LOCALE_LANG>"
export LANGUAGE="<LOCALE_LANG>"}
				}
			}
		}
	},
	'task' => { 'yast-language' => [ q{yast2 --ncurses language set lang=<LOCALE_YAST_LANG>} ] }
};

#my $ubuntuLanguages = [ 'ar', 'bg', 'bs', 'ca', 'cs', 'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi', 'fr', 'ga', 'gl', 'he', 'hi', 'hr', 'hu', 'ia', 'is', 'it', 'ja', 'kk', 'km', 'ko', 'lt', 'lv', 'mr', 'nb', 'nds', 'nl', 'nn', 'pa', 'pl', 'pt', 'ro', 'ru', 'si', 'sk', 'sl', 'sr', 'sv', 'tg', 'th', 'tr', 'ug', 'uk', 'vi', 'wa', 'zh-hans', 'zh-hant' ];
$common{'Ubuntu'} = {
    'packages' => {
        'DE' => [ 'language-pack-de', 'language-pack-de-base', 'manpages-de' ],
        'KR' => [ 'language-pack-ko', 'language-pack-ko-base', 'manpages-ko'],
        'JP' => [ 'language-pack-ja', 'language-pack-ja-base', 'manpages-ja' ]
    },
    'LANG' => {
        'EN' => 'en_US.UTF-8',
        'DE' => 'de_DE.UTF-8',
        'KR' => 'ko_KR.UTF-8',
        'JP' => 'ja_JP.UTF-8'
    },
    'default' => 'EN',
    'files'   => {
        'language' => {
            path  => '/etc/default/locale',
            save  => 1,
            chmod => 644,
            apply => {
                1 => {
                    replace => 1,
                    content => q{LANG="<LOCALE_LANG>"}
                }
            }
        },
        'bash_profile' => {
            path  => '/root/.bash_profile',
            save  => 'once',
            chmod => 644,
            apply => {
                1 => {
                    tail    => 1,
                    content => q{export LANG="<LOCALE_LANG>"
export LANGUAGE="<LOCALE_LANG>"}
                }
            }
        }
    }
};

$locale{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$locale{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$locale{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$locale{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$locale{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$locale{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$locale{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$locale{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$locale{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$locale{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$locale{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$locale{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$locale{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$locale{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$locale{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$locale{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$locale{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$locale{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$locale{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;
