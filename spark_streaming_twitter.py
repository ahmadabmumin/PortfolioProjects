import json
from kafka import SimpleProducer, KafkaClient
import tweepy
import configparser
import csv
import json


class TweeterStreamListener(tweepy.StreamListener):
    # Read the twitter stream and push it to Kafka

    def __init__(self, api):
        self.api = api
        
        super(tweepy.StreamListener, self).__init__()
        
        client = KafkaClient("10.0.2.15:9092")
        self.producer = SimpleProducer(client, async = True,
                          batch_send_every_n = 1000,
                          batch_send_every_t = 10)


    	
    def on_status(self, status):
        # asynchronously push this data to kafka queue        
        msg = status.text.encode('ascii', 'ignore')       
       
        try:
            self.producer.send_messages("covid19", msg)            
        except Exception as e:
            print(e)
            return False
        return True

    def on_error(self, status_code):
        print("Error received in kafka producer")
        print(status_code)
        return True 

    def on_timeout(self):
        return True 

if __name__ == '__main__':
  
    config = configparser.ConfigParser()
    
    consumer_key = '9dPk5kCjWfhszt1sZzbVlkeij'
    consumer_secret = '9cmg35fexT8g7GsKLuYrc8fy5ePmFgHELmrJRiuCNeTcLwimlK'
    access_key = '1380794153680863234-dVWMaX7fqxEklFDvn30LijE59nYbhF'
    access_secret = 'YpSHv9KxrYmXBGoxw2pe2ypADal4CcfWoBVvVXBD5ZU3z'
    

    # Create Auth object
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_key, access_secret)
    api = tweepy.API(auth)
    

    # Create stream and bind the listener to it
    stream = tweepy.Stream(auth, listener = TweeterStreamListener(api))
   

    # Filter rules pull all traffic for those filters in real time.      
    stream.filter(track = ['#bitcoin'])  
  
    
  
