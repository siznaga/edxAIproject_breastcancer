@@ -0,0 +1,382 @@

 #BReast Cancer

 # Introduction
 #######################################################################################################
 # Random forests, also known as random decision forests, are a popular ensemble method that can be used
 # to build predictive models for both classification and regression problems. Ensemble methods use 
 # multiple learning models to gain better predictive results - in the case of a random forest, 
 # the model creates an entire forest of random uncorrelated decision trees to arrive at the best 
 # possible answer.
 # 
 # To demonstrate how this works in practice - specifically in a classification context - 
 # I’ll be walking you through an example using a famous data set from the University of California,
 # Irvine (UCI) Machine Learning Repository. The data set, called the Breast Cancer Wisconsin (Diagnostic)
 # Data Set, deals with binary classification and includes features computed from digitized images of 
 # biopsies. The data set can be downloaded here. To follow this tutorial, you will need some familiarity
 # with classification and regression tree (CART) modeling. I will provide a brief overview of different 
 # CART methodologies that are relevant to random forest, beginning with decision trees. If you’d like to
 # brush up on your knowledge of CART modeling before beginning the tutorial, I highly recommend reading 
 # Chapter 8 of the book “An Introduction to Statistical Learning with Applications in R,” 
 # which can be downloaded here. http://faculty.marshall.usc.edu/gareth-james/
 #######################################################################################################

 # Decision Trees
 #######################################################################################################
 # Decision trees are simple but intuitive models that utilize a top-down approach in which the root node
 # creates binary splits until a certain criteria is met. This binary splitting of nodes provides a 
 # predicted value based on the interior nodes leading to the terminal (final) nodes. In a classification 
 # context, a decision tree will output a predicted target class for each terminal node produced. 
 # Although intuitive, decision trees have limitations that prevent them from being useful in machine 
 # learning applications. You can learn more about implementing a decision tree here.
 ########################################################################################################

 # Limitations to Decision Trees
 #######################################################################################################
 # Decision trees tend to have high variance when they utilize different training and test sets of the 
 # same data, since they tend to overfit on training data. This leads to poor performance on unseen data.
 # Unfortunately, this limits the usage of decision trees in predictive modeling. However, 
 # using ensemble methods, we can create models that utilize underlying decision trees as a foundation 
 # for producing powerful results.
 #######################################################################################################

 # Bootstrap Aggregating Trees
 #######################################################################################################
 # Through a process known as bootstrap aggregating (or bagging), it’s possible to create an ensemble 
 # (forest) of trees where multiple training sets are generated with replacement, meaning data instances
 # - or in the case of this tutorial, patients - can be repeated. Once the training sets are created,
 # a CART model can be trained on each subsample. This approach helps reduce variance by averaging the 
 # ensemble’s results, creating a majority-votes model. Another important feature of bagging trees is 
 # that the resulting model uses the entire feature space when considering node splits. Bagging trees 
 # allow the trees to grow without pruning, reducing the tree-depth sizes and resulting in high variance 
 # but lower bias, which can help improve predictive power. However, a downside to this process is that 
 # the utilization of the entire feature space creates a risk of correlation between trees, increasing bias
 # in the model.
 #######################################################################################################

 # Limitations to Bagging Trees
 #######################################################################################################
 # The main limitation of bagging trees is that it uses the entire feature space when creating splits in the
 # trees. If some variables within the feature space are indicative of certain predictions, you run the risk 
 # of having a forest of correlated trees, thereby increasing bias and reducing variance. However, a simple 
 # tweak of the bagging trees methodology can prove advantageous to the model’s predictive power.
 # 
 # Random Forest
 # Random forest aims to reduce the previously mentioned correlation issue by choosing only a subsample of 
 # the feature space at each split. Essentially, it aims to make the trees de-correlated and prune the trees 
 # by setting a stopping criteria for node splits, which I will cover in more detail later.
 ##########################################################################################################

 #Load Packages

 if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
 if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
 if(!require(ggcorrplot)) install.packages("ggcorrplot", repos = "http://cran.us.r-project.org")
 if(!require(GGally)) install.packages("GGally", repos = "http://cran.us.r-project.org")
 if(!require(randomForest)) install.packages("randomForest", repos = "http://cran.us.r-project.org")
 if(!require(e1071)) install.packages("e1071", repos = "http://cran.us.r-project.org")
 if(!require(ROCR)) install.packages("ROCR", repos = "http://cran.us.r-project.org")
 if(!require(pROC)) install.packages("pROC", repos = "http://cran.us.r-project.org")


 #Load Data

 # For this section, let's load the data .

 fileURL <- "https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.data"

 breast_cancer <- read.csv(fileURL, header = FALSE, sep = ",", quote = "\"'")

 ###################################################################################
 # Downloaded data has a 32 attributes with 569 rows, but in the link below
 # https://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+%28Diagnostic%29
 # Attributes details are given as
 # Attribute Information:
 # 1) ID number
 # 2) Diagnosis (M = malignant, B = benign)
 # 3-32)
 # 
 # Ten real-valued features are computed for each cell nucleus:
 #   
 # a) radius (mean of distances from center to points on the perimeter)
 # b) texture (standard deviation of gray-scale values)
 # c) perimeter
 # d) area
 # e) smoothness (local variation in radius lengths)
 # f) compactness (perimeter^2 / area - 1.0)
 # g) concavity (severity of concave portions of the contour)
 # h) concave points (number of concave portions of the contour)
 # i) symmetry
 # j) fractal dimension ("coastline approximation" - 1)

 # I have confusion that only 12 attribute names are given 
 # let me download the wdbc names file and check the attributes names
 ###################################################################################

 attribute <- "https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.names"
 mynames <- readLines(attribute)
 #mynames # gives the attributes information with extra data so i delete some unwanted lines in this.
 mynames <- mynames[109:140]
 mynames

 ##################################################################################
 # From this output data,
 # [23] "The mean, standard error, and \"worst\" or largest (mean of the three" 
 # [24] "largest values) of these features were computed for each image,"       
 # [25] "resulting in 30 features.  For instance, field 3 is Mean Radius, field"
 # [26] "13 is Radius SE, field 23 is Worst Radius."
 # So we get the attributes names correctly as below from above output
 ##################################################################################
 names(breast_cancer) <- c('id_number', 'diagnosis', 'radius_mean', 
            'texture_mean', 'perimeter_mean', 'area_mean', 
            'smoothness_mean', 'compactness_mean', 
            'concavity_mean','concave_points_mean', 
            'symmetry_mean', 'fractal_dimension_mean',
            'radius_se', 'texture_se', 'perimeter_se', 
            'area_se', 'smoothness_se', 'compactness_se', 
            'concavity_se', 'concave_points_se', 
            'symmetry_se', 'fractal_dimension_se', 
            'radius_worst', 'texture_worst', 
            'perimeter_worst', 'area_worst', 
            'smoothness_worst', 'compactness_worst', 
            'concavity_worst', 'concave_points_worst', 
            'symmetry_worst', 'fractal_dimension_worst')


 breast_cancer$id_number <- NULL

 #####################################################################################
 # Let’s preview the data set utilizing the head() function which will give the first 
 # 6 values of our data frame.
 #####################################################################################

 head(breast_cancer)

 ##################################################################################################
 # Next, we’ll give the dimensions of the data set; where the first value is the number of patients
 # and the second value is the number of features. We print the data types of our data set this is
 # important because this will often be an indicator of missing data, as well as giving us context
 # to anymore data cleanage.
 ##################################################################################################

 dim(breast_cancer)

 str(breast_cancer)

 #######################################################################################################
 #Class Imbalance
 # The distribution for diagnosis is important because it brings up the discussion of Class Imbalance
 # within Machine learning and data mining applications. Class Imbalance refers to when a target class 
 # within a data set is outnumbered by the other target class (or classes). This can lead to misleading
 # accuracy metrics, known as accuracy paradox, therefore we have to make sure our target classes aren’t 
 # imblanaced. We do so by creating a function that will output the distribution of the target classes.
 # 
 # NOTE: If your data set suffers from class imbalance I suggest reading documentation on upsampling
 # and downsampling.
 #######################################################################################################

 breast_cancer %>% 
   count(diagnosis) %>%
   group_by(diagnosis) %>%
   summarize(perc_dx = round((n / 569)* 100, 2))

 ###################################################################################################
 # Fortunately, this data set does not suffer from class imbalance.
 # Next we will use a useful function that gives us standard descriptive statistics for each feature
 # including mean, standard deviation, minimum value, maximum value, and range intervals.
 ###################################################################################################

 summary(breast_cancer)

 ###################################################################################################
 # We can see through the maximum row that our data varies in distribution, this will be important
 # when considering classification models. Standardization is an important requirement for many 
 # classification models that should be considered when implementing pre-processing. Some models 
 # (like neural networks) can perform poorly if pre-processing isn’t considered, so the describe()
 # function can be a good indicator for standardization. Fortunately Random Forest does not require 
 # any pre-processing (for use of categorical data see sklearn’s Encoding Categorical Data section).
 ###################################################################################################

 #Creating Training and Test Sets

 ###################################################################################################
 # We split the data set into our training and test sets which will be (pseudo) randomly selected 
 # having a 80-20% splt. We will use the training set to train our model along with some optimization, 
 # and use our test set as the unseen data that will be a useful final metric to let us know how well 
 # our model does.
 # When using this method for machine learning always be weary of utilizing your test set when 
 # creating models. The issue of data leakage is a grave and serious issue that is common in practice 
 # and can result in over-fitting. More on data leakage can be found in this Kaggle article
 ###################################################################################################

 set.seed(42, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(42)` instead
 trainIndex <- createDataPartition(breast_cancer$diagnosis, 
                                   p = .8, 
                                   list = FALSE, 
                                   times = 1)
 training_set <- breast_cancer[ trainIndex, ]
 test_set <- breast_cancer[ -trainIndex, ]

 ###################################################################################################
 # NOTE: What I mean when I say pseudo-random is that we would want everyone who replicates 
 # this project to get the same results. So we use a random seed generator and set it equal to a 
 # number of our choosing, this will then make the results the same for anyone who uses this 
 # generator, awesome for reproducibility.

 # Fitting Random Forest
 # The R version is very different because the caret package hyperparameter optimization will be 
 # done in the same chapter as fitting model along with cross validation. If you want an in more 
 # depth look check the python version.
 # 
 # Hyperparameters Optimization
 # Here we’ll create a custom model to allow us to do a grid search, I will see which parameters 
 # output the best model based on accuracy.
 # 
 # mtry: Features used in each split
 # ntree: Number of trees used in model
 # nodesize: Max number of node splits

 # Custom grid search 
 # From https://machinelearningmastery.com/tune-machine-learning-algorithms-in-r/
 ###################################################################################################

 customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
 customRF$parameters <- data.frame(parameter = c("mtry", "ntree", "nodesize"), 
                                   class = rep("numeric", 3), 
                                   label = c("mtry", "ntree", "nodesize"))
 customRF$grid <- function(x, y, len = NULL, search = "grid") {}
 customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
   randomForest(x, y, mtry = param$mtry, ntree=param$ntree, nodesize=param$nodesize, ...)
 }
 customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata)
 customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata, type = "prob")
 customRF$sort <- function(x) x[order(x[,1]),]
 customRF$levels <- function(x) x$classes

 #################################################################################################
 # Now that we have the custom settings well use the train method which crossvlidates and does 
 # a grid search, giving us the best parameters.
 #################################################################################################
 fitControl <- trainControl(## 10-fold CV
   method = "repeatedcv",
   number = 3, 
   ## repeated ten times
   repeats = 10)

 grid <- expand.grid(.mtry=c(floor(sqrt(ncol(training_set))), (ncol(training_set) - 1), floor(log(ncol(training_set)))), 
                     .ntree = c(100, 300, 500, 1000),
                     .nodesize =c(1:4))
 set.seed(42, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(42)` instead
 fit_rf <- train(as.factor(diagnosis) ~ ., 
                 data = training_set, 
                 method = customRF, 
                 metric = "Accuracy", 
                 tuneGrid= grid,
                 trControl = fitControl)

 # Let’s print out the different models and best model given by model.

 fit_rf$finalModel

 fit_rf

 plot(fit_rf)


 # Variable Importance
 ###################################################################################################
 # Once we have trained the model, we are able to assess this concept of variable importance.
 # A downside to creating ensemble methods with Decision Trees is we lose the interpretability 
 # that a single tree gives. A single tree can outline for us important node splits along with 
 # variables that were important at each split.
 # 
 # Forunately ensemble methods utilzing CART models use a metric to evaluate homogeneity of splits. 
 # Thus when creating ensembles these metrics can be utilized to give insight to important variables 
 # used in the training of the model. Two metrics that are used are gini impurity and entropy.
 # 
 # The two metrics vary and from reading documentation online, many people favor gini impurity due 
 # to the computational cost of entropy since it requires calculating the logarithmic function. 
 # For more discussion I recommend reading this article.
 # 
 # Here we define each metric:
 #   
 #   Gini Impurity=1−∑ipi
 # 
 # Entropy=∑i−pi∗log2pi
 # 
 # where pi is defined as the proportion of subsamples that belong to a certain target class.
 # For the package randomForest, I believe the gini index is used without giving the choice to 
 # the information gain.
 ###################################################################################################

 varImportance <- varImp(fit_rf, scale = FALSE)

 varImportanceScores <- data.frame(varImportance$importance)

 varImportanceScores <- data.frame(names = row.names(varImportanceScores), var_imp_scores = varImportanceScores$B)

 varImportanceScores

 # Visual Representation
 ggplot(varImportanceScores, 
        aes(reorder(names, var_imp_scores), var_imp_scores)) + 
   geom_bar(stat='identity', 
            fill = '#875FDB') + 
   theme(panel.background = element_rect(fill = '#fafafa')) + 
   coord_flip() + 
   labs(x = 'Feature', y = 'Importance') + 
   ggtitle('Feature Importance for Random Forest Model')


 # Out of Bag Error Rate
 ###################################################################################################
 # Another useful feature of Random Forest is the concept of Out of Bag Error Rate or OOB error rate.
 # When creating the forest, typically only 2/3 of the data is used to train the trees, this gives
 # us 1/3 of unseen data that we can then utilize.
 ###################################################################################################

 oob_error <- data.frame(mtry = seq(1:100), oob = fit_rf$finalModel$err.rate[, 'OOB'])

 paste0('Out of Bag Error Rate for model is: ', round(oob_error[100, 2], 4))

 ggplot(oob_error, aes(mtry, oob)) +  
   geom_line(colour = 'red') + 
   theme_minimal() + 
   ggtitle('OOB Error Rate across 100 trees') + 
   labs(y = 'OOB Error Rate')

 # Test Set Metrics
 ###################################################################################################
 # Now we will be utilizing the test set that was created earlier to receive another metric for 
 # evaluation of our model. Recall the importance of data leakage and that we didn’t touch the
 # test set until now, after we had done hyperparamter optimization.
 ###################################################################################################

 predict_values <- predict(fit_rf, newdata = test_set)

 ftable(predict_values, test_set$diagnosis)

 paste0('Test error rate is: ', round(((2/113)), 4))

 ######################################################################################################
 # Conclusions
 # For this tutorial we went through a number of metrics to assess the capabilites of our Random Forest, 
 # but this can be taken further when using background information of the data set. Feature engineering
 # would be a powerful tool to extract and move forward into research regarding the important features.
 # As well defining key metrics to utilize when optimizing model paramters.
 # 
 # There have been advancements with image classification in the past decade that utilize the images
 # intead of extracted features from images, but this data set is a great resource to become with
 # machine learning processes. Especially for those who are just beginning to learn machine learning
 # concepts. If you have any suggestions, recommendations, or corrections please reach out to me.
 ######################################################################################################








 456  Breastcancer.Rmd 

@@ -0,0 +1,456 @@

 # BREAST CANCER

 **Sathish kumar Subbarayelu**

 ## Introduction

 **Random forests, also known as random decision forests, are a popular ensemble method that can be used
  to build predictive models for both classification and regression problems. Ensemble methods use
  multiple learning models to gain better predictive results - in the case of a random forest, 
  the model creates an entire forest of random uncorrelated decision trees to arrive at the best 
  possible answer.**
 **To demonstrate how this works in practice - specifically in a classification context - 
  I’ll be walking you through an example using a famous data set from the University of California,
  Irvine (UCI) Machine Learning Repository. The data set, called the Breast Cancer Wisconsin (Diagnostic)
  Data Set, deals with binary classification and includes features computed from digitized images of 
  biopsies. The data set can be downloaded here. To follow this tutorial, you will need some familiarity
  with classification and regression tree (CART) modeling. I will provide a brief overview of different 
  CART methodologies that are relevant to random forest, beginning with decision trees. If you’d like to
  brush up on your knowledge of CART modeling before beginning the tutorial, I highly recommend reading 
  Chapter 8 of the book “An Introduction to Statistical Learning with Applications in R,” 
  which can be downloaded [here](http://faculty.marshall.usc.edu/gareth-james/) **


 ## Decision Trees


 **Decision trees are simple but intuitive models that utilize a top-down approach in which the root node
  creates binary splits until a certain criteria is met. This binary splitting of nodes provides a 
  predicted value based on the interior nodes leading to the terminal (final) nodes. In a classification 
  context, a decision tree will output a predicted target class for each terminal node produced. 
  Although intuitive, decision trees have limitations that prevent them from being useful in machine 
  learning applications. You can learn more about implementing a decision tree [here](https://scikit-learn.org/stable/modules/tree.html).**



 ## Limitations to Decision Trees


 **Decision trees tend to have high variance when they utilize different training and test sets of the 
  same data, since they tend to overfit on training data. This leads to poor performance on unseen data.
  Unfortunately, this limits the usage of decision trees in predictive modeling. However, 
  using ensemble methods, we can create models that utilize underlying decision trees as a foundation 
  for producing powerful results.**


 ## Bootstrap Aggregating Trees


 **Through a process known as bootstrap aggregating (or bagging), it’s possible to create an ensemble 
  (forest) of trees where multiple training sets are generated with replacement, meaning data instances
  - or in the case of this tutorial, patients - can be repeated. Once the training sets are created,
  a CART model can be trained on each subsample. This approach helps reduce variance by averaging the 
  ensemble’s results, creating a majority-votes model. Another important feature of bagging trees is 
  that the resulting model uses the entire feature space when considering node splits. Bagging trees 
  allow the trees to grow without pruning, reducing the tree-depth sizes and resulting in high variance 
  but lower bias, which can help improve predictive power. However, a downside to this process is that 
  the utilization of the entire feature space creates a risk of correlation between trees, increasing bias
  in the model. **


 ## Limitations to Bagging Trees


 **The main limitation of bagging trees is that it uses the entire feature space when creating splits in the
  trees. If some variables within the feature space are indicative of certain predictions, you run the risk 
  of having a forest of correlated trees, thereby increasing bias and reducing variance. However, a simple 
  tweak of the bagging trees methodology can prove advantageous to the model’s predictive power.**

 ## Random Forest
 **Random forest aims to reduce the previously mentioned correlation issue by choosing only a subsample of 
  the feature space at each split. Essentially, it aims to make the trees de-correlated and prune the trees 
  by setting a stopping criteria for node splits, which I will cover in more detail later.**


 ## Load Packages

 ```{r}
 if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
 if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
 if(!require(ggcorrplot)) install.packages("ggcorrplot", repos = "http://cran.us.r-project.org")
 if(!require(GGally)) install.packages("GGally", repos = "http://cran.us.r-project.org")
 if(!require(randomForest)) install.packages("randomForest", repos = "http://cran.us.r-project.org")
 if(!require(e1071)) install.packages("e1071", repos = "http://cran.us.r-project.org")
 if(!require(ROCR)) install.packages("ROCR", repos = "http://cran.us.r-project.org")
 if(!require(pROC)) install.packages("pROC", repos = "http://cran.us.r-project.org")
 ```


 ## Load Data


 For this section, let's load the data .

 ```{r}
 fileURL <- "https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.data"

 breast_cancer <- read.csv(fileURL, header = FALSE, sep = ",", quote = "\"'")
 ```



 **Downloaded data has a 32 attributes with 569 rows, but in the link below      
  https://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+%28Diagnostic%29      
  Attributes details are given as          
  Attribute Information:                
  1) ID number                    
  2) Diagnosis (M = malignant, B = benign)             
  3-32)**                      

 **Ten real-valued features are computed for each cell nucleus:**               

 ** a) radius (mean of distances from center to points on the perimeter)       
  b) texture (standard deviation of gray-scale values)               
  c) perimeter                
  d) area              
  e) smoothness (local variation in radius lengths)               
  f) compactness (perimeter^2 / area - 1.0)                    
  g) concavity (severity of concave portions of the contour)             
  h) concave points (number of concave portions of the contour)              
  i) symmetry                
  j) fractal dimension ("coastline approximation" - 1)**               

 **I have confusion that only 12 attribute names are given 
  let me download the wdbc names file and check the attributes names**


 ```{r}
 attribute <- "https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.names"
 mynames <- readLines(attribute)
 #mynames # gives the attributes information with extra data so i delete some unwanted lines in this.
 mynames <- mynames[109:140]
 mynames
 ```



 **From this output data,**

 [23] "The mean, standard error, and \"worst\" or largest (mean of the three"           
 [24] "largest values) of these features were computed for each image,"                    
 [25] "resulting in 30 features.  For instance, field 3 is Mean Radius, field"             
 [26] "13 is Radius SE, field 23 is Worst Radius."                
 So we get the attributes names correctly as below from above output               


 ```{r}
 names(breast_cancer) <- c('id_number', 'diagnosis', 'radius_mean', 
            'texture_mean', 'perimeter_mean', 'area_mean', 
            'smoothness_mean', 'compactness_mean', 
            'concavity_mean','concave_points_mean', 
            'symmetry_mean', 'fractal_dimension_mean',
            'radius_se', 'texture_se', 'perimeter_se', 
            'area_se', 'smoothness_se', 'compactness_se', 
            'concavity_se', 'concave_points_se', 
            'symmetry_se', 'fractal_dimension_se', 
            'radius_worst', 'texture_worst', 
            'perimeter_worst', 'area_worst', 
            'smoothness_worst', 'compactness_worst', 
            'concavity_worst', 'concave_points_worst', 
            'symmetry_worst', 'fractal_dimension_worst')


 breast_cancer$id_number <- NULL
 ```



  Let’s preview the data set utilizing the head() function which will give the first 
  6 values of our data frame.


 ```{r}
 head(breast_cancer)
 ```


  Next, we’ll give the dimensions of the data set; where the first value is the number of patients
  and the second value is the number of features. We print the data types of our data set this is
  important because this will often be an indicator of missing data, as well as giving us context
  to anymore data cleanage.


 ```{r}
 dim(breast_cancer)

 str(breast_cancer)
 ```



 ## Class Imbalance


  **The distribution for diagnosis is important because it brings up the discussion of Class Imbalance
  within Machine learning and data mining applications. Class Imbalance refers to when a target class 
  within a data set is outnumbered by the other target class (or classes). This can lead to misleading
  accuracy metrics, known as [accuracy paradox](https://en.wikipedia.org/wiki/Accuracy_paradox), 
  therefore we have to make sure our target classes aren’t imblanaced. We do so by creating a function
  that will output the distribution of the target classes.**

 **NOTE: If your data set suffers from class imbalance I suggest reading documentation on upsampling
  and downsampling.**


 ```{r}
 breast_cancer %>% 
   count(diagnosis) %>%
   group_by(diagnosis) %>%
   summarize(perc_dx = round((n / 569)* 100, 2))
 ```



  Fortunately, this data set does not suffer from class imbalance.
  Next we will use a useful function that gives us standard descriptive statistics for each feature
  including mean, standard deviation, minimum value, maximum value, and range intervals.


 ```{r}
 summary(breast_cancer)
 ```



  We can see through the maximum row that our data varies in distribution, this will be important
  when considering classification models. Standardization is an important requirement for many 
  classification models that should be considered when implementing pre-processing. Some models 
  (like neural networks) can perform poorly if pre-processing isn’t considered, so the describe()
  function can be a good indicator for standardization. Fortunately Random Forest does not require 
  any pre-processing (for use of categorical data see [sklearn’s Encoding Categorical Data section](https://scikit-learn.org/stable/modules/preprocessing.html#encoding-categorical-features)).


 ## Creating Training and Test Sets

  We split the data set into our training and test sets which will be (pseudo) randomly selected 
  having a 80-20% splt. We will use the training set to train our model along with some optimization, 
  and use our test set as the unseen data that will be a useful final metric to let us know how well 
  our model does.
  When using this method for machine learning always be weary of utilizing your test set when 
  creating models. The issue of data leakage is a grave and serious issue that is common in practice 
  and can result in over-fitting. More on data leakage can be found in this [Kaggle article](https://www.kaggle.com/wiki/Leakage)


 ```{r}
 set.seed(42, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(42)` instead
 trainIndex <- createDataPartition(breast_cancer$diagnosis, 
                                   p = .8, 
                                   list = FALSE, 
                                   times = 1)
 training_set <- breast_cancer[ trainIndex, ]
 test_set <- breast_cancer[ -trainIndex, ]
 ```



  NOTE: What I mean when I say pseudo-random is that we would want everyone who replicates 
  this project to get the same results. So we use a random seed generator and set it equal to a 
  number of our choosing, this will then make the results the same for anyone who uses this 
  generator, awesome for reproducibility.


 ## Fitting Random Forest


  The R version is very different because the caret package hyperparameter optimization will be 
  done in the same chapter as fitting model along with cross validation. If you want an in more 
  depth look check the python version.

 ## Hyperparameters Optimization


  Here we’ll create a custom model to allow us to do a grid search, I will see which parameters 
  output the best model based on accuracy.

  mtry: Features used in each split        
  ntree: Number of trees used in model          
  nodesize: Max number of node splits              

  Custom grid search 
  From https://machinelearningmastery.com/tune-machine-learning-algorithms-in-r/



 ```{r}
 customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
 customRF$parameters <- data.frame(parameter = c("mtry", "ntree", "nodesize"), 
                                   class = rep("numeric", 3), 
                                   label = c("mtry", "ntree", "nodesize"))
 customRF$grid <- function(x, y, len = NULL, search = "grid") {}
 customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
   randomForest(x, y, mtry = param$mtry, ntree=param$ntree, nodesize=param$nodesize, ...)
 }
 customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata)
 customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata, type = "prob")
 customRF$sort <- function(x) x[order(x[,1]),]
 customRF$levels <- function(x) x$classes
 ```



  Now that we have the custom settings well use the train method which crossvalidates and does 
  a grid search, giving us the best parameters.



 ```{r}
 fitControl <- trainControl(## 10-fold CV
   method = "repeatedcv",
   number = 3, 
   ## repeated ten times
   repeats = 10)

 grid <- expand.grid(.mtry=c(floor(sqrt(ncol(training_set))), (ncol(training_set) - 1), floor(log(ncol(training_set)))), 
                     .ntree = c(100, 300, 500, 1000),
                     .nodesize =c(1:4))
 set.seed(42, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(42)` instead
 fit_rf <- train(as.factor(diagnosis) ~ ., 
                 data = training_set, 
                 method = customRF, 
                 metric = "Accuracy", 
                 tuneGrid= grid,
                 trControl = fitControl)
 ```



 **Let’s print out the different models and best model given by model.**



 ```{r}
 fit_rf$finalModel

 fit_rf

 plot(fit_rf)
 ```


 ## Variable Importance


  Once we have trained the model, we are able to assess this concept of variable importance.
  A downside to creating ensemble methods with Decision Trees is we lose the interpretability 
  that a single tree gives. A single tree can outline for us important node splits along with 
  variables that were important at each split.

  Forunately ensemble methods utilzing CART models use a metric to evaluate homogeneity of splits. 
  Thus when creating ensembles these metrics can be utilized to give insight to important variables 
  used in the training of the model. Two metrics that are used are gini impurity and entropy.

  The two metrics vary and from reading documentation online, many people favor gini impurity due 
  to the computational cost of entropy since it requires calculating the logarithmic function. 
  For more discussion I recommend reading this [article](https://github.com/rasbt/python-machine-learning-book/blob/master/faq/decision-tree-binary.md).

  Here we define each metric:

                Gini Impurity=1−∑ipi

                Entropy=∑i−pi∗log2pi

  where pi is defined as the proportion of subsamples that belong to a certain target class.
  For the package randomForest, I believe the gini index is used without giving the choice to 
  the information gain.


 ```{r}
 varImportance <- varImp(fit_rf, scale = FALSE)

 varImportanceScores <- data.frame(varImportance$importance)

 varImportanceScores <- data.frame(names = row.names(varImportanceScores), var_imp_scores = varImportanceScores$B)

 varImportanceScores
 ```


 ## Visual Representation


 ```{r}
 ggplot(varImportanceScores, 
        aes(reorder(names, var_imp_scores), var_imp_scores)) + 
   geom_bar(stat='identity', 
            fill = '#875FDB') + 
   theme(panel.background = element_rect(fill = '#fafafa')) + 
   coord_flip() + 
   labs(x = 'Feature', y = 'Importance') + 
   ggtitle('Feature Importance for Random Forest Model')

 ```


 ## Out of Bag Error Rate


  Another useful feature of Random Forest is the concept of Out of Bag Error Rate or OOB error rate.
  When creating the forest, typically only 2/3 of the data is used to train the trees, this gives
  us 1/3 of unseen data that we can then utilize.


 ```{r}
 oob_error <- data.frame(mtry = seq(1:100), oob = fit_rf$finalModel$err.rate[, 'OOB'])

 paste0('Out of Bag Error Rate for model is: ', round(oob_error[100, 2], 4))

 ggplot(oob_error, aes(mtry, oob)) +  
   geom_line(colour = 'red') + 
   theme_minimal() + 
   ggtitle('OOB Error Rate across 100 trees') + 
   labs(y = 'OOB Error Rate')
 ```



 ## Test Set Metrics


  Now we will be utilizing the test set that was created earlier to receive another metric for 
  evaluation of our model. Recall the importance of data leakage and that we didn’t touch the
  test set until now, after we had done hyperparamter optimization.


 ```{r}
 predict_values <- predict(fit_rf, newdata = test_set)

 ftable(predict_values, test_set$diagnosis)

 paste0('Test error rate is: ', round(((2/113)), 4))
 ```


 ## Conclusions


 **For this tutorial we went through a number of metrics to assess the capabilites of our Random Forest, 
  but this can be taken further when using background information of the data set. Feature engineering
  would be a powerful tool to extract and move forward into research regarding the important features.
  As well defining key metrics to utilize when optimizing model paramters.**

 **There have been advancements with image classification in the past decade that utilize the images
  intead of extracted features from images, but this data set is a great resource to become with
  machine learning processes. Especially for those who are just beginning to learn machine learning
  concepts. If you have any suggestions, recommendations, or corrections please reach out to me.**








