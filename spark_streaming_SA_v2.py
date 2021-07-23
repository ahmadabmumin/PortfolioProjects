from pyspark import SparkConf, SparkContext
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils
import operator
import numpy as np
import matplotlib.pyplot as plt
import sys
from textblob import TextBlob
import re
import string


def main():
    conf = SparkConf().setMaster("local[3]").setAppName("Streaming")
    sc = SparkContext(conf=conf)

    # Creating a streaming context with batch interval of 20 sec  
    ssc = StreamingContext(sc, 20)#batch every 20s
    ssc.checkpoint("/checkpoint") 
    
    counts = stream(ssc, 200) #stop after 200s
    make_plot(counts)
    


def make_plot(counts):
    
    #This function plots the counts of positive and negative words for each timestep.
    
    positiveCounts = []
    negativeCounts = []
    time = []
    for value in counts:
        if (len(value) == 2): 
            positiveValue = value[1]
            positiveCounts.append(positiveValue[1])
            negativeValue = value[0]
            negativeCounts.append(negativeValue[1])
        else:            
            continue
      
    for i in range(len(counts)):
        time.append(i)

    posLine = plt.plot(time, positiveCounts,'bo-', label='Positive')
    negLine = plt.plot(time, negativeCounts,'go-', label='Negative')
    plt.axis([0, len(counts), 0, max(max(positiveCounts), max(negativeCounts))+50])
    plt.xlabel('Timestamp')
    plt.ylabel('Polarity')
    plt.legend(loc = 'upper left')
    plt.show()



def updateFunction(newValues, runningCount):
    if runningCount is None:
       runningCount = 0
    return sum(newValues, runningCount) 


def resolve_emoticon(line):
   emoticon = {
    	':-)' : 'smile',
        ':)'  : 'sad',
    	':))' : 'very happy',
    	':)'  : 'happy',
    	':((' : 'very sad',
    	':('  : 'sad',
    	':-P' : 'tongue',
    	':-o' : 'gasp',
    	'>:-)': 'angry'
   }   
   for key in emoticon:
      line = line.replace(key, emoticon[key])
   return line
  

def abb_en(line):
   abbreviation_en = {
    'u': 'you',
    'thr': 'there',
    'asap': 'as soon as possible',
    'lv' : 'love',    
    'c' : 'see'
   }
   
   abbrev = ' '.join (abbreviation_en.get(word, word) for word in line.split())
   return (resolve_emoticon(abbrev))  

def remove_features(data_str):
   
    url_re = re.compile(r'https?://(www.)?\w+\.\w+(/\w+)*/?')    
    mention_re = re.compile(r'@|#(\w+)')  
    RT_re = re.compile(r'RT(\s+)')
    num_re = re.compile(r'(\d+)')
    
    data_str = str(data_str)
    data_str = RT_re.sub(' ', data_str)  
    data_str = data_str.lower()  
    data_str = url_re.sub(' ', data_str)   
    data_str = mention_re.sub(' ', data_str)  
    data_str = num_re.sub(' ', data_str)
    return data_str





def stream(ssc, duration):    
    kstream = KafkaUtils.createDirectStream(
    ssc, topics = ['bitcoin'], kafkaParams = {"metadata.broker.list": '10.0.2.15:9092'})   
    tweets = kstream.map(lambda x: x[1].encode("ascii", "ignore"))
    

    # We keep track of a running total counts and print it at every time step.
    RDD_sentiment = tweets.map(lambda x:remove_features(x)).map(lambda x:x.lower()).map(lambda x: abb_en(x)).map(lambda x: TextBlob(x).sentiment.polarity)

    positive = RDD_sentiment.map(lambda senti_value: ('Positive', 1) if (senti_value > 0.0) else ('Positive', 0))
    negative = RDD_sentiment.map(lambda senti_value: ('Negative', 1) if (senti_value < 0.0) else ('Negative', 0))    
    
    positive.pprint()   
    negative.pprint()
    
    

    allSentiments = positive.union(negative)
    sentimentCounts = allSentiments.reduceByKey(lambda x,y: x+y)
    runningSentimentCounts = sentimentCounts.updateStateByKey(updateFunction)
    runningSentimentCounts.pprint()
    
    # The counts variable hold the word counts for all time steps
    counts = []
    sentimentCounts.foreachRDD(lambda t, rdd: counts.append(rdd.collect()))
    
    # Start the computation
    ssc.start() 
    ssc.awaitTerminationOrTimeout(duration) 
    ssc.stop()
    
    print("***************counts*****************")
    print(counts)

    return counts


if __name__=="__main__":
    main()
