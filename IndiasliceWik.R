library(googleVis)
library(XML)
library(tm)
library(wordcloud)
library(reshape2)
library(ggplot2)
library(stringr)
library(corrplot)

# Pulling in data from wikipedia

URL1 <- "http://en.wikipedia.org/wiki/States_and_union_territories_of_India"
tablesfromURL1 <- readHTMLTable(URL1)
states<-tablesfromURL1[["States of India"]]
ut<-tablesfromURL1[["Union Territories"]]

# For religion related data, we need to go to another page

URL2 <- "http://en.wikipedia.org/wiki/Demographics_of_India"
tablesfromURL2 <- readHTMLTable(URL2)
reltable<-tablesfromURL2[["Table 2: Census information for 2001"]]
"Saving Raw Files --- Helps if wikipedia changes these pages"

# The data retrieval is going to be affected by how Wikipedia changes the information. So, let's 
# save the tables for later use/replication. These files are available for download on github: https://github.com/patilv/IndiasliceWik
save(states,file="states.rda")
save(ut,file="ut.rda")
save(reltable,file="reltable.rda")

###################Cleaning data related to States and Union Territories(UTs)

# We are interested in studying States and UTs with respect to only a few vars- Official languages, 
# Sex ratio, Ratio (or percentage) of urban to total population of State or UT, and literacy rate

states <- states[c(2,6,10:12)]
ut<-ut[c(2,5,11:13)]

# Let's just rename all column names to make them easy to merge
names(states) <- c("Name","OfficialLanguages","LiteracyRateinPercent", "UrbanToTotalPopPercent","SexRatio")
names(ut)<-c("Name","OfficialLanguages","LiteracyRateinPercent", "UrbanToTotalPopPercent","SexRatio")

#Combine both dataframes
stateut<-rbind(states,ut)  

# Some names have to be changed for States and UTs

levels(stateut$Name)[20]<-"Orissa" # from Odisha [5] (Orissa)
levels(stateut$Name)[34]<-"Delhi" # from National Capital Territory of Delhi - GeoChart takes in Delhi,not New Delhi
levels(stateut$Name)[35]<-"Pondicherry" #from Puducherry (Pondicherry)

# Cleaning the SexRatio Column 
stateut$SexRatio<-gsub(",", "", stateut$SexRatio) # Remove commas
stateut$SexRatio[stateut$SexRatio == "916[3]"] <- 916 # Replace one value 

# Convert relevant columns to numeric
stateut$LiteracyRateinPercent<-as.numeric(as.character(stateut$LiteracyRateinPercent))
stateut$SexRatio<-as.numeric(as.character(stateut$SexRatio))
stateut$UrbanToTotalPopPercent<-as.numeric(as.character(stateut$UrbanToTotalPopPercent))

############### Let's now deal with the column with Official Languages##########
stateut$OfficialLanguages<-as.character(stateut$OfficialLanguages) # Convert factor to character
stateut$OfficialLanguages<-gsub("[[:punct:]]", "", stateut$OfficialLanguages) # Remove punctuations

#######Remove some words and numbers
stateut$OfficialLanguages<-gsub("citation needed", "", stateut$OfficialLanguages)
stateut$OfficialLanguages<-gsub("regional", "", stateut$OfficialLanguages)
stateut$OfficialLanguages<-gsub("and", "", stateut$OfficialLanguages)
stateut[,2] <- str_replace_all(stateut[,2],"4","") #Only this worked, why? will try to figure out later
stateut[,2] <- str_replace_all(stateut[,2],"6","") #ditto

# Convert letters to lower case

stateut$OfficialLanguages<-tolower(stateut$OfficialLanguages)

############################ Cleaning Religion Table##################

reltable[,1] <- str_replace_all(reltable[,1],"%","Percent") #First Column - replacing % sign with "Percent"
reltable[,1] <- str_replace_all(reltable[,1],"10","Ten") #First Column - replacing "10" with "Ten"
reltable[,1] <- gsub("[^A-Za-z]","",reltable[,1]) # Replacing everything but letters with a blank in the first column

# The following is sufficient to arrive at the desired column values, without performing three changes suggested above.
#The above helped me learn a bit more

reltable[,1]<-c("Percentofpopulation","GrowthofPopPercent91Through01","SexRatio","LiteracyRateforAge7andabove",
                "WorkParticipationRate","Ruralsexratio","Urbansexratio","ChildsexratioUptoAge6")

# Changing Column names
names(reltable) <- gsub("[^A-Za-z]", "", names(reltable))# Renaming columns by removing everything but letters

# Remove all "%"signs in columns 2-8
for (i in 2:8){reltable[,i] <- str_replace_all(reltable[,i],"%","")}

###Viewing the stateut (States and Union Territories) table ####
stateuttabledisplay<-gvisTable(stateut, options=list(width=800, height=400))
plot(stateuttabledisplay)
print(stateuttabledisplay,file="stateuttabledisplay.html")

###Viewing the religion table####

reltabledisplay<-gvisTable(reltable, options=list(width=800, height=200))
plot(reltabledisplay)
print(reltabledisplay,file="reltabledisplay.html")


############################### Now, let's start plotting

# GeoChart of Literacy Rate

litratechart<-gvisGeoChart(stateut, locationvar="Name", colorvar="LiteracyRateinPercent",
                           options=list(title="Literacy Rates by State",region='IN',displayMode="region",resolution="provinces",
                                        colorAxis="{colors:['red','orange','yellow','blue', 'green']}",
                                        width=540,height=400))
plot(litratechart)
print(litratechart,file="litratechart.html")

# Dot Plot of Literacy Rate by State
ggplot(stateut,aes(x=reorder(Name,LiteracyRateinPercent),y=LiteracyRateinPercent,color="Name"))+
  geom_point(size=5) +theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+xlab("")+ylab("")+
  ggtitle("Literacy Rate (in %)")+coord_flip()

# GeoChart of Sex Ratio

sexratiochart<-gvisGeoChart(stateut, locationvar="Name", colorvar="SexRatio",
                            options=list(region='IN',displayMode="region",resolution="provinces",
                                         colorAxis="{colors:['red','orange','yellow','blue', 'green']}",
                                         width=540,height=400))
plot(sexratiochart)
print(sexratiochart,file="sexratiochart.html")

# Dot Plot of Sex Ratio

ggplot(stateut,aes(x=reorder(Name,SexRatio),y=SexRatio,color="Name"))+
  geom_point(size=5) +theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+xlab("")+ylab("")+
  ggtitle("Sex Ratio (Number of females to 1000 males)")+coord_flip()

# GeoChart of Urban to Total Population Percent

Urbanchart<-gvisGeoChart(stateut, locationvar="Name", colorvar="UrbanToTotalPopPercent",
                         options=list(region='IN',displayMode="region",resolution="provinces",
                                      colorAxis="{colors:['red','orange','yellow','blue', 'green']}",
                                      width=540,height=400))
plot(Urbanchart)
print(Urbanchart,file="Urbanchart.html")
# Dot Plot of Urban to Total Population Percent

ggplot(stateut,aes(x=reorder(Name,UrbanToTotalPopPercent),y=UrbanToTotalPopPercent,color="Name"))+
  geom_point(size=5) +theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+xlab("")+ylab("")+
  ggtitle("Ratio of Urban population to Total population of State/Union Territory (in %)")+coord_flip()

######################################################################

#Let's see which States/UTs have the highest number of Official languages

# Counting the number of languages per State/UT

stateut$langs<-strsplit(stateut$OfficialLanguages," ")
stateut$NumOfficialLangs<-sapply(stateut$langs, length)

# Plot

ggplot(stateut,aes(x=reorder(Name,NumOfficialLangs),y=NumOfficialLangs,color="red"))+
  geom_point(size=8)+coord_flip()+ theme(axis.text.y = element_text(color="black"))+
  theme(axis.text.x = element_text(color="black"))+ theme(legend.position="none")+xlab("")+ylab("")+
  ggtitle("Number of Official Languages in Different States and Union Territories")


# A Word cloud and and a graph to see the most popular official languages

langCorpus<-Corpus(VectorSource(stateut$OfficialLanguages))# Creating Corpus
langTDM<-TermDocumentMatrix(langCorpus) 
tdMatrix <- as.matrix(langTDM) # creating a data matrix
sortedMatrix<-sort(rowSums(tdMatrix),decreasing=TRUE) # calculate row sum of each language and sort in descending order (high freq to low)
cloudFrame<-data.frame(word=names(sortedMatrix),freq=sortedMatrix)#extracting names from named list in prev command and binding together into a dataframe with frequencies - called cloudFrame, names in separate columns
wordcloud(cloudFrame$word,cloudFrame$freq,random.order=TRUE,colors=brewer.pal(8,"Dark2"),min.freq=1)

ggplot(cloudFrame,aes(x=reorder(word,freq),y=freq,color="red"))+geom_point(size=8)+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  theme(legend.position="none")+xlab("")+ylab("")+
  ggtitle("Languages and number of States and Union Territories they are spoken in")+coord_flip()


# Let's look at sex ratio, Ratio of Urban Population to Total Population, and Literacy Rate

comparegraphtable<-stateut[c(1,3:5,7)] # Creating another table with select columns
comparegraphtable$SexRatio<-(comparegraphtable$SexRatio)/10 # Done for scaling purposes - So, sex ratio now is on 100...# of Females to 100 males
comparegraphtable$Name<-reorder(comparegraphtable$Name,comparegraphtable$SexRatio) # Will be plotting with States ordered by Sex Ratio
comparegraphmelt<-melt(comparegraphtable,id.vars="Name") # Modifying table for ggplot

# And, the plot
ggplot(comparegraphmelt,aes(x=Name,y=value,color=variable,group=variable))+
  geom_line(size=1)+geom_point(size=5) +coord_flip()+theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  xlab("")+ylab("")+
  ggtitle("Sex Ratio, Ratio of Urban Population to Total Population, Literacy Rate, and Number of Official Languages")

####### Correlation Matrix of Sex Ratio, Urban To Total Population Percent, 
#Literacy Rate, and Num of Official Languages --- R-Graphics Cookbook, Chang

corrtable<-comparegraphtable[c(-1)]
corrmatrix<-cor(corrtable) #store corr matrix
col <- colorRampPalette(c("#BB4444", "#EE9988", "#FFFFFF", "#77AADD", "#4477AA")) #Color scheme, verbatim from the R Graphics cookbook - Chang
corrplot(corrmatrix, method="shade", shade.col=NA, tl.col="black", tl.srt=45, 
         col=col(200), addCoef.col="black", addcolorlabel="no", order="AOE")

#Preparing the religion table for use in ggplot2

meltreltable<-melt(reltable,id.vars="Composition")
meltreltable$value<-as.numeric(as.character(meltreltable$value)) # Converting to numeric

# Scaling all sex ratios to 100, instead of 1000
for (i in 1:nrow(meltreltable)){if(meltreltable$value[i]>200){meltreltable$value[i]<-meltreltable$value[i]/10}}

ggplot(meltreltable,aes(x=variable,y=Composition,color=value,size=value))+geom_point()+scale_colour_gradientn(colours = c("darkgreen", "green", "orange","red","darkred"))+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  xlab("")+ylab("")+ggtitle("Religion and Demographics - I")

ggplot(meltreltable,aes(x=Composition,y=value,color=variable))+geom_point(size=10)+coord_flip()+
  theme(axis.text.y = element_text(color="black"))+theme(axis.text.x = element_text(color="black"))+
  xlab("")+ylab("")+ggtitle("Religion and Demographics - II")

##################################################################################################
