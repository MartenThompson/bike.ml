# bike.ml

A three part project to 

1. collect and export phone accelerometer and gyroscope data
2. train a classifier to identifying biking motion
3. deploy the model to a phone app

Every month or so I wonder "how much have I biked the past few weeks?" and I'm reminded that my phone - with 15 billion transistors and more sensors than I can imagine - is incapable of answering that. For that you need a smartwatch, or another peripheral, or a subscription. I think it would be fun to make a tiny app that will answer that question for me every month or so.

Apart from loosely tracking biking and vindicating a belief that my phone can/should do this natively, I am interested in building this myself because I miss statistics, ML, and playing with data. Workout detection absolutely exists as a feature in many apps that are far more functional that this aims to be. This is for fun.

## Part 1: Collection

I need training data.

The app in `bike_ml_collection/` samples phone accelerometer and gyroscope values at 5 Hz. It contains a UI switch to indicate whether you are biking or not, and it allows you to export the data for later use.

## Part 2: Classification [WIP]

1.  5 Hz is intentionally high; we can always subsample. 
2.  data cleanup: delete the ~10 seconds after biking is toggled; not yet biking
3. Making the classifier

    1. priorities: simple, lightweight, 
    2. curious about input shape
    3. how many "biking" classifications before we trust we are?
    4. Type I/II error weights 
 

## Part 3: Deploy [WIP]

* just seeing if it can classify motion accurately is nice
* "app" considerations: 
    * should we ramp up/down the rate at which we ping the classifier?
* reach goals
    * gps
    * 12 hours of background activity < 25% battery 