#!/usr/bin/perl

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

my $ranFile = '/tmp/random128k';
my $ranMd5  = '7d16290a7fc033363c829d37436fea1d';
my $targetFilePrefix = 'ranFile';
my $targetPath = '/tmp/nfs/stuff1';
my $netFs   = 'NFS';
my $sleep   = 15;
my $maxRetry = 4;
  
print "START $netFs File Copy to $targetPath !\n";

print "Removed old files ...\n";

while ( 1 ) {

   my $startFileCount = 0;
   my $endFileCount = 99;

   my $myRetryCount = 0;
   `rm -f $targetPath/*`;
   if ($? != 0 ) {
      if ( $myRetryCount > $maxRetry ) {
         print "MAX Retry attempts ... aborting! \n";
         exit 1;
      } else {
         print "?? REMOVING $targetPath hung :: Host may be down ... sleeping $sleep ... retry (max $maxRetry) ...\n";
         sleep $sleep;
         $myRetryCount++;
         redo;
      }
   } else {
      print "Removed $targetPath/* ...\n";
   }

   while ( $endFileCount <= 7000 ) {

      $myRetryCount = 0;
   
      print "Copying $targetFilePrefix$startFileCount to $targetFilePrefix$endFileCount ...\n";
      for ($i = $startFileCount; $i <= $endFileCount; $i++ ) {
         `cp $ranFile $targetPath/$targetFilePrefix$i`;
         if ($? != 0 ) {
            if ( $myRetryCount > $maxRetry ) {
               print "MAX Retry attempts ... aborting! \n";
               exit 1;
            } else {
               print "?? COPY $targetFilePrefix$i hung :: Host may be down ... sleeping $sleep ... retry (max $maxRetry) ...\n";
               sleep $sleep;
               $myRetryCount++;
	       redo;
            }
         }
      }
      print "Copying done ...\n";
      for ($i = $startFileCount; $i <= $endFileCount; $i++ ) {
         if ( !-e "$targetPath/$targetFilePrefix$i" ) {
            if ( $myRetryCount > $maxRetry ) {
               print "MAX Retry attempts ... aborting! \n";
               exit 1;
            } else {
               print "?? MISSING $targetFilePrefix$i :: Host may be down ... sleeping $sleep ... retry (max $maxRetry) ...\n";
               sleep $sleep;
               $myRetryCount++;
	       redo;
            }
         } else {
            $md5 = `md5sum $targetPath/$targetFilePrefix$i | awk '{print \$1}'`;
            if ( $md5 =~ /^md5sum/ ) {
               if ( $myRetryCount > $maxRetry ) {
                  print "MAX Retry attempts ... aborting! \n";
                  exit 1;
               } else {
                  print "?? MD5SUM $targetFilePrefix$i hung :: Host may be down ... sleeping $sleep ... retry (max $maxRetry) ...\n";
                  sleep $sleep;
                  $myRetryCount++;
	          redo;
               }
            } else {
               chomp( $md5 );
               if ( $md5 ne $ranMd5 ) {
                  print "!!!! $netFs ERROR: MISMATCH MD5SUM. GOT $md5 on $targetFilePrefix$i EXPECTED $ranMd5 !!!! \n";
                  exit 1;
               }
            }
         }
      }
      print "MD5SUM OK for FILES $targetFilePrefix$startFileCount to $targetFilePrefix$endFileCount ...\n";
   
      print "Repeat ...\n";

      $startFileCount += 100;
      $endFileCount += 100;

   }

   print "Reset to files count to 0 ...\n";

}
