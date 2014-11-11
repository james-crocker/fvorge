#!/usr/bin/perl -w

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

use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
   'vmname' => {
      type => "=s",
      help => "Name of the virtual machine being snapshot",
      required => 1,
   },
   'snapshotname' => {
      type => "=s",
      help => "Name for the snapshot",
      required => 1,
   },
   'snapshotdescription' => {
      type => "=s",
      help => "Description for the snapshot",
      required => 1,
   },
   'snapshotmemory' => {
      type => "!",
      help => "Include memory in snapshot",
      required => 0,
   },
   'snapshotquiesce' => {
      type => "!",
      help => "Quiesce during snapshtot",
      required => 0,
   },
);

# read/validate options
Opts::add_options(%opts);
Opts::parse();
Opts::validate();

Util::connect();

# look up virtual machine and unregister it
my $vm_name             = Opts::get_option('vmname');
my $snapshotName        = Opts::get_option('snapshotname');
my $snapshotDescription = Opts::get_option('snapshotdescription');
my $snapshotMemory      = Opts::get_option('snapshotmemory');
my $snapshotQuiesce     = Opts::get_option('snapshotquiesce');

if (defined($vm_name)) {
   my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                       filter => {'config.name' => $vm_name});
   if (!defined($vm_view)) {
      die "Did not find virtual machine '$vm_name'!";
   }
   
   if ( !defined $snapshotMemory ) {
       $snapshotMemory = 0;
   }
   
   if ( !defined $snapshotQuiesce ) {
   	   $snapshotQuiesce = 0;
   }
   
   Util::trace(0, "Snapshotting VM " . $vm_view->name . "\n");
   $vm_view->CreateSnapshot(name => $snapshotName,
                            description => $snapshotDescription,
                            memory => $snapshotMemory,
                            quiesce => $snapshotQuiesce);
   Util::trace(0, "Snapshot complete for VM: " . $vm_view->name . "\n");
}

Util::disconnect();

1;
