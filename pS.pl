#!/usr/bin/env perl
use strict; use warnings;

use JSON;
use Data::Dumper;
use Lingua::EN::Fathom;
use Switch;

my $TIME=0;
my $SUBREDDIT="error";
my %feats=(
  'wordcount'=>'',
  'subreddit'=>'',
  'readability'=>'',
  'depth'=>'',
  'ups'=>'',
#  'author'=>'',
  'time'=>'',
  'depth'=>''
#  'body'=>''
  );

if(!@ARGV) {
    print "USAGE: $0 jsonfile jsonfile jsonfile ...\n";
    exit;
}
#arff header
print '@relation ',"'Reddit Upboats' \n\n";
for my $k (keys %feats){
	print "\@attribute $k ";
	if($k eq "subreddit") { print "{AskReddit, funny, gaming, iama, pics, politics, programming, science, technology, worldnews, wtf}\n";} 
	else {print "numeric\n";}
}
print "\n\@data\n\n";


while(@ARGV){    
    my $file = shift;
    my $j=JSON->new->allow_nonref;
    open my $fh, $file or die "Cannot open file $file: $!\n";
    my $json = $j->decode(<$fh>);
    close($fh);
	#print $json->[0]->{'data'}->{'children'}->[0]->{'data'}->{'ups'}, "\n";
	$TIME=$json->[0]->{'data'}->{'children'}->[0]->{'data'}->{'created_utc'};
	$SUBREDDIT=$json->[0]->{'data'}->{'children'}->[0]->{'data'}->{'subreddit'};


	findch(0,$json->[1]->{'data'}->{'children'});
}

sub findch{
	my $idx=shift; $idx+=1;
	return if $idx>10;
	my $node = shift;
	for my $r (@{$node}){

		my $body = $r->{'data'}->{'body'};
		my $n=0;
		for my $k (keys %feats) {
			switch ($k){
					case "readability" { my $re=readability($body); $feats{$k}=$re?$re:0;}
					case "wordcount" { $feats{$k}=wordcount($body);}
					case "time" { $feats{$k}=$r->{'data'}->{'created_utc'}-$TIME;}
					case "depth" { $feats{$k}=$idx;}
					case "subreddit" { $feats{$k}=$SUBREDDIT;}
					else {$feats{$k}=$r->{'data'}->{$k};}
			}
			print "," if $n!=0;
			print $feats{$k};
			$n+=1;
		}
		print "\n";
		

#downs levenshtein author replies parent_id link_id body id likes subreddit_id created_utc ups name created subreddit body_html
#		print $r->{'data'}->{'ups'},"\t",readability($body),"\t", $r->{'data'}->{'author'},"\t",  wordcount($body),"\t", $idx,"\t",$r->{'data'}->{'created_utc'}-$TIME,"\t",$body, "\n";
		my $reply=$r->{'data'}->{'replies'};
		findch($idx,$reply->{'data'}->{'children'}) if ($reply);
	}
}

sub refkeys { #because Dumper is useless
	my $i =shift;
	return join(" ", keys %{$i});
}

sub wordcount {
	my $text =shift;
	$text =~ tr/'/ /;
	$text =~ tr/,/ /;
	return substr(`echo '$text' | wc -w`,0,-1);
	#return -1;
}

sub readability { #Flesch-Kincaid
    my $text = new Lingua::EN::Fathom;
	$text->analyse_block(shift,0);
	#return $text->flesch;
	#return $text->fog;
	#return $text->kincaid;
	return $text->percent_complex_words;
	
}
