#!/usr/bin/env bash
#
# Outline of whats going on
#
#

#all the folders that will be used
if false; then
   mkdir {csv,data,results}
fi


if  false ; then 				#new stories
    #get stories
    ./scripts/getStories.pl
fi

##get specific subreddit top stories
##./getStories.pl worldnews wtf


#create arff file
ARFF=csv/$(date +%F)-small.arff



if  true; then 				#new data file
    biglist=$(for d in data/*/; do
	for json in $(ls ${d}*|head -n 3); 
	    do echo -n "$json "; 
	done
    done)


    #requires perl packages JSON and Lingua::EN::Fathom
    #if biglist containes spaces, bad things happen im sure
    ./scripts/jsonTo.pl arff time,subreddit,wordcount,readability,depth,ups $biglist > $ARFF
fi


#WEKA
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

if false; then
    #change pruning(.05 to .5) and min number (1 to 2)
    java -Djava.awt.headless=true -classpath /usr/share/java/weka/weka.jar  weka.classifiers.meta.CVParameterSelection -c 2 -t $ARFF -P "C .05 .5 5" -P "M 1 2 2" -X 10 -S 1 -W weka.classifiers.trees.J48 --

    java -classpath /usr/share/java/weka/weka.jar weka.experiment.Experiment -l weka.exp.xml -r -D -O
fi


#MALLET
ATTS='time,ups,body'
./scripts/jsonTo.pl $ATTS $biglislt > csv/forMallet.txt 
MALLET_HOME="$HOME/bin/mallet"
$MALLET_HOME/bin/mallet import-file --input csv/forMallet.txt --output csv/words.mallet
$MALLET_HOME/bin/mallet train-classifier --input csv/words.mallet --trainer MaxEnt --trainer NaiveBayes --training-portion .9 --num-trials 10 --output-classifier $(date +%F).classifier
