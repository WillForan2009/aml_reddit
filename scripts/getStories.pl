#!/usr/bin/env perl

# get top stories between {MIN,MAX}AGE
#
# Fetch top reddit page for desired subreddits
# (desired subred. found in dir tree of $DATADIR)
# download json of stories fitting requirements (to directory in $DATADIR)
#
# USAGE: $0 [subredit subreddit]
# #
# e.g. ./getStories.pl wtf pics
# or
# ./getStories.pl
#
# with no arguments:
# look at all folders in DATADIR as subreddits
# downloads only if there are less then $MAXSTORIES in the directory
#
#
# willforan@gmail.com

use strict; use warnings;


use LWP::Simple;
use File::Basename;

my $DATADIR='/home/wforan1/Dropbox/School/2010_08-12Fall/834ML/Assignments/aml_reddit/data/';
my $MAXSTORIES=10;
my $MINAGE=16;
my $MAXAGE=25;

if(!@ARGV) {
    opendir my($dir), $DATADIR; 
    my @subred=readdir $dir; 
    closedir $dir;
    shift @subred;shift @subred;  #get rid of '.' & '..' 
    				  #faster then  grep { !/^\./ } readdir ? 
    for my $subred (@subred){ 
	    opendir my($sr_dir), "$DATADIR$subred"; #or die
	    my $count = grep {!/^\.+$/} readdir $sr_dir; #scalar context is ar len
	    closedir $sr_dir;
	    print "subred:$subred ($count)\n";
	    if($count < $MAXSTORIES ) {
		getsubreddit($subred);
	    }
    }
}
else{
    while($ARGV[0]) { getsubreddit(shift); }
}


sub getsubreddit{
    my $subred = shift;
    my $match=0; my $i=0;
    # example $url=http://www.reddit.com/r/politics/top
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

	    if($comments > 50 && ($hours >$MINAGE && $hours < $MAXAGE) ){
		    print "$fn\n $url\n";
		    #DOES NOT MKDIR, will fail if subred dir DNE
		    getstore("$url.json?limit=500", "$DATADIR/$subred/$fn") or die "could not open:$!";	    
		    $match+=1;
		    return if $match == 10;
	    }
	    return if $i == 20;
	    #print "\n$match matches in $i stories\n";
    }
}
