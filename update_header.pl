#!/usr/bin/perl -w
use strict;

# description: Takes all of the .c files in the directory, and makes sure that the header file is up-to-date with all functions. Any new function protypes that are missing from the header file are added into it.

# usage: perl update_header.pl code.c header.h


my $infile = $ARGV[0];
my $header_file = $ARGV[1];
my %function_headers;
#Store all the potentially new protypes in the %function_headers hash:
open(IN, '<', $infile);
while (<IN>)
{
	if (is_header($_))
	{
		chomp $_;
		$function_headers{"$_;\n"} = 0;
	}
}
close IN;

#Then go through the headerfile, print the line if it's not a duplicate header, then print the new headers.
my %seen_lines;
open(IN, '<', $header_file);
open(my $fh, '>', "./tmp.h");
my $header_flag = 0;
while (<IN>)
{
        if (is_header($_))
        {       
		$header_flag++;
                if(defined($function_headers{$_}))
		{
			$function_headers{$_} = 1;
		}
        }
	if ($header_flag) { 
		$seen_lines{$_} += 1; 
	}
	else { 
		$seen_lines{$_} = 0; 
	}
	if ($_ =~ m/\#endif/)
	{
		foreach (keys %function_headers)
		{
			unless ($function_headers{$_} == 1)
			{
				print $fh $_;
			}
		}
		print $fh "\n";
	}
	unless ($_ =~ m/^$/ && $header_flag || $seen_lines{$_} > 1) {
		 print $fh $_;
	}
}
close IN;

`mv ./tmp.h $header_file`;

sub is_header
{
	my $line = shift;
	if ($line =~ m/^void|^int|^t_llist|^char/)
	{
		return (1);
	}
	return (0);
}
