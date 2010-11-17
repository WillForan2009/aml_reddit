#!/usr/bin/env perl
use strict; use warnings;
#
#Grab JSON formated comments for top stories 
#	between 16 and 25 hours old
#

# example $url=http://www.reddit.com/r/politics/top

use LWP::Simple;
if(!@ARGV) {
    #my @subred=`ls -F|grep \/\$`;
    my @subred=('askreddit', 'funny', 'gaming','iama','pics','politics','programming',	'science', 'technology', 'worldnews', 'wtf'	);
    for my $subred (@subred){ 
		#system("mkdir data/$subred");
	    my $count=`ls data/$subred|wc -l`;
		chomp($count);
	    if($count < 10 ) {
		print "subred:$subred ($count)\n";
		getsubreddit($subred);
	    }
    }
}
else{
	while(@ARGV){
		getsubreddit(shift);
	}
}


sub getsubreddit{
    my $subred = shift;
    my $match=0; my $i=0;
    my $page = get("http://www.reddit.com/r/${subred}/top");

    while($page =~ m:<div class="entry.*?<a class="title.*? href=".*?".*?>(.*?)</a>.*?<p class="tagline">.*?(\d+) hours.*?<a class="comments.*? href="(.*?)".*?(\d+) comments:gs){
    #iama,askreddit
    #while($page =~ m:<div class="entry.*?<a class="title.*? href="(.*?)".*?>(.*?)</a>.*?<p class="tagline">.*?(\d+) hours.*?(\d+) comments:gs){
	    $i+=1;
	    my $title=$1;
	    my $hours=$2;
	    my $url=$3;
	    my $comments=$4;
	    my @fn=split('/',$url);
	    my $fn=${fn[7]}; #5 on selfposts

	    if($comments > 50 && ($hours >16 && $hours < 25) ){
		    print "$fn\n $url\n";
		    #my $ls=`ls $subred$fn`;
		    #chomp($ls);
		    getstore("$url.json?limit=500", "$subred/data/$fn") or die "could not open:$!";	    
		    $match+=1;
		    return if $match == 10;
	    }
	    return if $i == 20;
	    #print "\n$match matches in $i stories\n";
    }
}
