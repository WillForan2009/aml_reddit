#!/usr/bin/env perl
use strict; use warnings;

if(@ARGV<3 || !$ARGV[1]=~/^(arff)|(csv)$/) {
    print "USAGE: $0 arff|csv attribute,attribute jsonfile jsonfile jsonfile ...\n";
    print"\twhere attribute is a comma delerated combination of any:\n";
    print"\tbody,time,subreddit,wordcount,readability,depth\n";
    exit;
}


use JSON;
use Data::Dumper;
use Lingua::EN::Fathom;
use Switch;

my $TIME=0;
my $SUBREDDIT="error";
my %feats;
my @UPS=( '<3', '>=3' );
my %UPS=( '<3'=>'0', '>=3'=>'1');
my @ORDER; #=('time','subreddit','wordcount','readability','depth','ups');
#downs levenshtein author replies parent_id link_id body id likes subreddit_id created_utc ups name created subreddit body_html


my $type=shift;
@ORDER=split(',', shift);
#push  @ORDER, 'ups'; #this doesn't always go last




#arff header
if($type eq 'arff'){
    #@ORDER=('time','subreddit','wordcount','readability','depth','ups');
    print '@relation ',"'Reddit Upboats-", time,"' \n\n";
    for my $k (@ORDER){
	    print "\@attribute $k ";
	    if($k eq "ups") { print '{' , join(',',values(%UPS)), "}\n"; } 
	    elsif($k eq "subreddit") { print "{AskReddit, funny, gaming, IAmA, pics, politics, programming, science, technology, worldnews, WTF}\n";} 
	    else {print "numeric\n";}
    }
    print "\n\@data\n\n";
}

#csv header
else{ #($type eq 'csv'){
    #@ORDER=('body','subreddit','wordcount','readability','depth','ups');
    print join(',',@ORDER), "\n";
}


foreach my $i (@ORDER) { $feats{$i} = '';}

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
		#recurse
		my $reply=$r->{'data'}->{'replies'};
		findch($idx,$reply->{'data'}->{'children'}) if ($reply);

		
		my $body = $r->{'data'}->{'body'};
		if(!$body){return}
		
		#only compute if asked
		my $re;my $wc;
		if($feats{'readability'}||$feats{'wordcount'}) {
		    my ($re, $wc)=textanaly($body);
		    if(!$re){$re=0;} 
		}

		my $uniCount=$body=~s/[^[:ascii:]]//g;

		for my $k (@ORDER) {
			switch ($k){
					case "time" { my $age= $r->{'data'}->{'created_utc'}-$TIME; return if($age<0); $feats{$k}=$age;}
					case "readability" { $feats{$k}=$re}
					case "wordcount" { $feats{$k}=$wc;}
					case "depth" { $feats{$k}=$idx;}
					case "subreddit" { $feats{$k}=$SUBREDDIT;}
					#case "hasUnicode" { $feats{$k}=$body=~s/[^[:ascii:]]//g;}
					case "hasUnicode" { $feats{$k}=$uniCount?$uniCount:0;}
					case "hasCAPS" { my $has=0; $has++ while($body=~/[A-Z]{2,}/g); $feats{$k}=$has;}
					case "hasNum" { my $has=0; $has++ while($body=~/[0-9]+/g); $feats{$k}=$has;}
					case "hasFormat" {my $has=0; $has++ while($body=~/(\[.+\])|(_.+_)|(\*.+\*)/g); $feats{$k}=$has;}
					case "isQuestion" {my $has=0; $has++ while($body=~/(what)|(how)|(where)|(when)|(who)|(\?)/ig); $feats{$k}=$has;}
					case "isMeta" {my $has=0; $has++ while($body=~/(karma)|(vote)|(upboat)/ig); $feats{$k}=$has;}
					case "body" { 
					
						     #for SIDE
						     $body=~s/,/ /g; 
						     $feats{'body'}='"'.$body.'"';
						     
						     #for MALLET
						     #$body=~s/\n/ /g; #for mallet 
						     #$feats{'body'}=$body;

						     } #remove , and add quotes
					case "ups" {
					    my $ups=$r->{'data'}->{'ups'}-$r->{'data'}->{'downs'};
					   # $feats{'ups'}=$ups;
					    for my $condition (@UPS){
					    	if(eval("$ups $condition")){
					            $feats{'ups'}=$UPS{$condition};
					            last;
					        }
					    }
					}
					else {$feats{$k}=$r->{'data'}->{$k};}
			}
		}
		my @output;
		for my $feat (@ORDER){ push  @output, $feats{$feat} }
		print join(', ',@output), "\n";
		

	}
}


sub textanaly{ 
    my $text = new Lingua::EN::Fathom;
    
    my $raw=shift;
    $text->analyse_block($raw,0);
    return ($text->percent_complex_words, $text->num_chars);

    #return $text->flesch;
    #return $text->fog;
    #return $text->kincaid;
    #return $text->num_words;

	
}

sub refkeys { #because Dumper is useless
	my $i =shift;
	return join(" ", keys %{$i});
}

