#!/usr/bin/perl -w
use strict;
use Term::ANSIColor;

#Description: This is a script that checks your code for any unused functions. A summary table is printed if the -p flag is used. The functions that are just listed 1x are not used in the program and should probably be removed, ultimately. The script begins by catting all of the C src files into one file, then running through and removing the unused functions. This happens cyclically, until all the unused portions of the code have been removed. This is necessary because the first unused function calls other functions that become unused once the first calling function is removed. After all unused code is removed, the code is distrubted to files containing only 5 functions each. Note that this script also removes spaces where there are more than one space in a row. Script should be run in the directory that contains the code being operated on.

#usage: perl id_unused_functions.pl

`touch temp_combo.c && rm temp_combo.c`;
`ls -r *.c | xargs cat >> temp_combo.c`;

my $total_function_calls_1 = 0;
my $total_function_calls_2 = -1;
my $i = 0;

my $print_flag = 0;
my $split_flag = 0;
if (defined($ARGV[0]))
{
	$print_flag = ($ARGV[0] eq "-p") ? 1 : 0;
	if ($ARGV[0] eq "-s") {$split_flag = 1;}
	if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help")
	{
		print color("green"), "\nDescription: \n\t\tScript to clean up C project and remove unused functions\nUsage:\n\t\tperl id_unused_functions.pl [-h] [-p]\n\t\tUse -p to print summary tables and -h or --help to print this message\n\n", color("reset");
	exit;
	}
}

if (defined($ARGV[1]))
{
	if ($ARGV[1] eq "-s") {$split_flag = 1;}
}

while ($total_function_calls_1 != $total_function_calls_2)
{
	my %functions;
	set_function_calls_vars($total_function_calls_1, $total_function_calls_2, $i);
	open(IN, '<', "temp_combo.c");
	while(<IN>)
	{
		if ($_ =~ m/(^char|^int|^void)[\t\s]+\*?\*?(.*)\(.*\)/)
		{
			$functions{$2} = 0;
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
				if ($line =~ m/$_/)
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
		if  ($total_function_calls_2 == -1) { printf("\n\n\n"); }
		printf("\t%-25s\tNumber of Calls\n", "Function");
		printf("\t------------------------------------------------\n");
	}
	foreach(keys(%functions))
	{
		if ($i % 2 == 0)
		{
			$total_function_calls_1 += $functions{$_};
		}
		else
		{
			$total_function_calls_2 += $functions{$_};
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
	$i++;
}

#under construction...
#Now to split it up into files with no more than 5 functions each:
#if ($split_flag == 1)
#{
#	$i = 0;
#	my $j = 0;
#	open(IN, '<', "temp_combo.c");
#        while(<IN>){
#		if ($_ 
#
#}

#################
## Subroutines ##
#################
#This sets the function that counts the function call occurences to zero
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
