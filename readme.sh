#!/usr/bin/env bash
#
# Outline of whats going on
#
#

if  false ; then 				#new stories
    #get stories
    ./scripts/getStories.pl
fi

##get specific subreddit top stories
##./getStories.pl worldnews wtf


#create arff file
ARFF=csv/$(date +%F)-small.arff



if  false ; then 				#new data file
    biglist=$(for d in data/*/; do
	for json in $(ls ${d}*|head -n 3); 
	    do echo -n "$json "; 
	done
    done)


    #requires perl packages JSON and Lingua::EN::Fathom
    #if biglist containes spaces, bad things happen im sure
    ./scripts/parse.pl $biglist > $ARFF
fi



if false ; then					#new baseline
    LEARNERS="classifiers.bayes.NaiveBayes
    classifiers.trees.J48
    classifiers.functions.SMO
    classifiers.rules.JRip"
    #clusterers.EM" 


    #do weka
    for LEARNER in $LEARNERS; do echo $LEARNER; 
	java -Djava.awt.headless=true -classpath /usr/share/java/weka/weka.jar weka.$LEARNER  -t $ARFF -c 2  -d results/$LEARNER.model > results/$(basename $ARFF .arff)-$LEARNER.txt
    done;
    #use -l to recall a model, c is which attr to use as class, -d saves model
fi


#change pruning
java -Djava.awt.headless=true -classpath /usr/share/java/weka/weka.jar weka.classifiers.meta.CVParameterSelection -P"C .1 .8 5" -X 10 -S1 -W weka.classifiers.trees.J48 --
