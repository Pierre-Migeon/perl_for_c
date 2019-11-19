#!/usr/bin/perl -w
use strict;
use Term::ANSIColor;
use POSIX;

#Description: This is a script that checks your code for any unused functions. A summary table is printed if the -p flag is used. The functions that are just listed 1x are not used in the program and should probably be removed, ultimately. The script begins by catting all of the C src files into one file, then running through and removing the unused functions. This happens cyclically, until all the unused portions of the code have been removed. This is necessary because the first unused function calls other functions that become unused once the first calling function is removed. After all unused code is removed, the code is distrubted to files containing only 5 functions each. Note that this script also removes spaces where there are more than one space in a row. Script should be run in the directory that contains the code being operated on.

#usage: perl id_unused_functions.pl

my $i = 0;
my $continue = 1;

my $print_flag = 0;
my $split_flag = 0;
if (defined($ARGV[0]))
{
	$print_flag = ($ARGV[0] eq "-p") ? 1 : 0;
	if ($ARGV[0] eq "-s") {$split_flag = 1;}
	if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help")
	{
		print color("green"), "\nDescription: \n\t\tScript to clean up C project and remove unused functions\nUsage:\n\t\tperl condense_c_code.pl [-h] [-p] [-s]\n\t\tUse -p to print summary tables, -s to split sum code into sub-files and -h or --help to print this message\n\n", color("reset");
	exit;
	}
}

if (defined($ARGV[1]))
{
	if ($ARGV[1] eq "-s") {$split_flag = 1;}
}

`touch temp_combo.c && rm temp_combo.c`;
`ls -r *.c | xargs cat >> temp_combo.c`;

my @num_functions;
my $header;
while ($continue)
{
	$continue = 0;
	my %functions;
	open(IN, '<', "temp_combo.c");
	while(<IN>)
	{
		if ($_ =~ m/(^char|^int|^void)[\t\s]+\*?\*?(.*)\(.*\)/)
		{
			$functions{$2} = 0;
		}
		if ($_ =~ m/(\#include.*\.h.*\n)/)
		{
			$header = $1;
		}
	}
	close IN;

	open(IN, '<', "temp_combo.c");
	while(<IN>){
		unless ($_ =~ m/#/)
		{
			my $line = $_;
			foreach(keys %functions)
			{
				if ($line =~ m/[^A-Za-z0-9_]$_\(/)
				{
					$functions{$_}++;
				}
			}
		}
	}
	close IN;

	#Print the summary table:
        if ($print_flag)
        {
		if  ($i == 0) { printf("\n\n\n"); }
		printf("\t%-25s\tNumber of Calls\n", "Function");
		printf("\t------------------------------------------------\n");
	}
	foreach(keys(%functions))
	{
		if (($functions{$_} == 1) && $_ !~ m/^main$/ )
		{
			$continue = 1;
		}
		if ($print_flag)
		{
			if ($functions{$_} == 1) { printf("\t%-25s\t\t\t%s\n", colored($_, "red"), colored($functions{$_}, "red")); }
			else { printf("\t%-25s\t\t%s\n", $_, $functions{$_}); }
		}
	}
	if ($print_flag)
	{
		print "\n\n\n";
	}

	my $outfile;
	my $flag = 0;
	my $last_line_empty = 0;
	#This time scan through the file to get the output file, which will have removed the non-used functions:
	open(IN, '<', "temp_combo.c");
	while(<IN>){
		if ($_ =~ m/(char|int|void)\t\*?\*?(.*)\(.*\)/)
        	{       
			if ($functions{$2} < 2 && !($2 =~ m/main/))
        		{
				$flag = 1;
			}
		}
		unless (($flag == 1) || (is_empty_line($_) && $last_line_empty))
		{
			if ($_ =~ m/(^char|^int|^void)[\s]+\*?\*?(.*)\(.*\)/)
                        {
                        	$_ =~ s/(^char|^int|^void)[\s]+(\*?\*?.*\(.*\))/$1\t$2/;
                        }
			$outfile .= $_;
		}
		if (is_empty_line($_))
        	{
        	        $last_line_empty = 1;
        	}
		elsif ($flag == 0) 
		{
			$last_line_empty = 0;
		}
		if ($_ =~ m/^}/ && $flag == 1)
		{
			$flag = 0;
		}
	}
	close IN;
	open (my $fh, '>', "./temp.c");
	print $fh $outfile;
	`mv  temp.c temp_combo.c`;
	$num_functions[$i] = keys %functions;
	$i++;
}

if ($split_flag == 1)
{
	printf ("Removed %i functions... The remaining %i functions were split up into files containing 5 functions each\n", $num_functions[0] - $num_functions[$i - 1], $num_functions[$i - 1]);
}
else
{
	printf ("Use the -s flag to remove %i functions... %i functions will remain in the program\n", $num_functions[0] - $num_functions[$i - 1], $num_functions[$i - 1]);
}

#Now to split it up into files with no more than 5 functions each:
if ($split_flag == 1)
{
	`if [ ! -d "./tmp/" ]; then mkdir ./tmp/; fi`;
	my $outfile2 = $header;
	$i = ceil($num_functions[$i - 1] / 5);
	my $j = 0;
	open(IN, '<', "temp_combo.c");
        while(<IN>){
		if ($_ =~ m/^}/) { $j++; }
		unless ($_ =~ m/$header/) { $outfile2 .= $_; }
		if ($j == 5 || eof)
		{
			open (my $fh, '>', "./tmp/push_swap_$i.c");
			print $fh $outfile2;
			$outfile2 = $header;
			$j = 0;
			$i--;
		}
	}
	close IN;
}
`rm temp_combo.c`;

#################
## Subroutines ##
#################
#This sets the function that counts the function call occurences to zero
#no longer used, kept for posterity...
sub set_function_calls_vars
{
	my $i;
	my $var_1;
	my $var_2;

	($var_1, $var_2, $i) = @_;

	if ($i % 2 == 0)
	{
		$_[0] = 0;
	}
	else
	{
		$_[1] = 0;
	}
}

#This checks to see that the line is empty
sub is_empty_line
{
	my $line = shift;
	if ($line =~ m/^$/)
	{
		return (1);
	}
	return (0);
}
