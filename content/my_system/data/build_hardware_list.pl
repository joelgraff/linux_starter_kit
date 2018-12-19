#!/usr/local/bin/perl
use strict;
use warnings;
use utf8;
use JSON;

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

#run lshw to get system specs
my $output = `lshw`;

my @sections = split /\*-/, $output;

my @hw_list = qw(
                memory cpu display firewire storage ide multimedia communication network
                usb usb:0 usb:1 usb:2 usb:3 usb:4 usb:5 usb:6 usb:7 usb:8 usb:9
                cdrom
               );

my @components = ();

for my $section (@sections) {

    foreach my $token (@hw_list) {

        if (index($section, $token) == 0) {

            if (index($section, "UNCLAIMED") > -1) {
                last;
            }

            my @lines = split /\n/, $section;

            map { s/^\s+|\s+$//g; } @lines;

            my %tuples = ();

            foreach my $line (@lines) {

                my @fields = split /\:/, $line;

                if (scalar @fields != 2) {
                    next;
                }

                if ($token eq "memory") {

                    if ($fields[0] eq "size") {
                           $tuples{$fields[0]} = $fields[1];
                       }
                }
                elsif ($token eq "cpu") {

                    if ($fields[0] eq "product" ||
                        $fields[0] eq "vendor" ||
                        $fields[0] eq "capacity" ||
                        $fields[0] eq "width") {
                            $tuples{$fields[0]} = $fields[1];
                        }
                }
                else {
                    
                    if ($fields[0] eq "product" ||
                        $fields[0] eq "vendor" ||
                        $fields[0] eq "description") {
                            $tuples{$fields[0]} = $fields[1];
                        }
                }
            }

            if(!grep { $_ eq $token } @components) {
                push (@components, $token);
            }

            #print %tuples;
            open my $fh, ">", "$token.csv";
            
            foreach my $item (keys %tuples) {

                my $data = $tuples{$item};
                $data =~ s/,/_/ig;

                print $fh "$item,$data\n"
            }
            close $fh;
        }
    }
}

open my $fh, ">", "components.csv";
foreach my $component (@components) {
    print $fh "$component,$component.csv\n";
}
close $fh;
