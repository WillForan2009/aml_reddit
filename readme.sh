#!/usr/bin/env bash
#
# Outline of whats going on
#
#

#all the folders that will be used
if false; then
   mkdir {csv,data,results}
fi

if false; then 				#new stories
    #get stories
    ./scripts/getStories.pl
fi

##get specific subreddit top stories
##./getStories.pl worldnews wtf

#interesting stats
if false; then
    #modified to print actual vote count
    for f in data/*; do find ./$f |head -n11|grep './data/.*/'  ;done|xargs scripts/jsonTo.pl csv subreddit,wordcount,readability,ups >ups

    for sr in {AskReddit,funny,gaming,IAmA,pics,politics,programming,science,techn logy,worldnews,WTF}; do
	    echo -n "$sr,"; 
	    grep $sr ups|awk 'BEGIN{t=0;w=0}{t=t+$4;w=w+$2}END{print t","NR","w}';
    done  
fi

#create arff file
PNUM=7
DESC=hasQuote
ARFF=csv/$(date +%F)-${PNUM}${DESC}.arff



if false; then 				#new data file
    biglist=$(for d in data/*/; do
	for json in $(ls ${d}*|head -n $PNUM); 
	    do echo -n "$json "; 
	done
    done)


    #requires perl packages JSON and Lingua::EN::Fathom
    #if biglist containes spaces, bad things happen im sure
    FEATS='isMeta,isQuestion,hasQuote,hasUnicode,hasNum,hasCAPS,hasFormat,wordcount,readability,depth,time,subreddit,ups'
    ./scripts/jsonTo.pl arff $FEATS  $biglist > $ARFF

    #weka.filters.unsupervised.attribute.Discretize-unset-class-temporarily-F-B2-M-1.0-Rlast
fi


#WEKA
if  false; then					#new baseline
    OUTDIR=results/$(date +%F)/${DESC} 
    mkdir -p $OUTDIR
    LEARNERS="classifiers.bayes.NaiveBayes
    classifiers.trees.J48
    classifiers.rules.JRip"
    #classifiers.functions.SMO
    #clusterers.EM" 
    
    #numeric learners
    #LEARNERS=" classifiers.trees.M5P
    #classifiers.functions.SMOreg
    #classifiers.rules.M5Rules"
    #clusterers.EM" 

    #do weka
    for LEARNER in $LEARNERS; do 
    	echo $LEARNER; 
	java -Djava.awt.headless=true -classpath /usr/share/java/weka/weka.jar weka.$LEARNER  -t $ARFF -d $OUTDIR/$LEARNER.model > $OUTDIR/$LEARNER.txt
    done;
    #use -l to recall a model, c is which attr to use as class, -d saves model

    #java -classpath /usr/share/java/weka/weka.jar weka.classifiers.meta.Vote -S 1 -B "weka.classifiers.rules.JRip -F 3 -N 2.0 -O 2 -S 1" -B "weka.classifiers.bayes.NaiveBayes " -R MAX
fi

if false; then
    #change pruning(.05 to .5) and min number (1 to 2)
    java -Djava.awt.headless=true -classpath /usr/share/java/weka/weka.jar  weka.classifiers.meta.CVParameterSelection -t $ARFF -P "C .05 .5 5" -P "M 1 2 2" -X 10 -S 1 -W weka.classifiers.trees.J48 --

    java -classpath /usr/share/java/weka/weka.jar weka.experiment.Experiment -l weka.exp.xml -r -D -O
fi


#MALLET
if false; then
    ATTS='ups,body'
    #./scripts/jsonTo.pl $ATTS $biglislt > csv/forMallet.csv 
    MALLET_HOME="$HOME/bin/mallet"
    $MALLET_HOME/bin/mallet import-file --input csv/forMallet.csv --output csv/words.mallet
    $MALLET_HOME/bin/mallet train-classifier --input csv/words.mallet --trainer MaxEnt --trainer NaiveBayes --training-portion .7 --num-trials 5 --output-classifier results/$(date +%F)/mallet.classifier |tee results/$(date +%F)/mallet.out.txt
fi

if true; then
#finally done
#java -classpath /usr/share/java/weka/weka.jar weka.classifiers.meta.Vote -S 1 -B "weka.classifiers.rules.JRip -F 3 -N 2.0 -O 2 -S 1" -B "weka.classifiers.bayes.NaiveBayes " -R MAX
java -classpath /usr/share/java/weka/weka.jar weka.classifiers.meta.Vote -l final_model_bayes+rule.model -T final.arff |tee final_output.txt
fi
