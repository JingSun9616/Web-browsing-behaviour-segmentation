install.packages("stream")
##### Session 1 Comparison
library("stream")
con <- gzcon(url(paste("http://archive.ics.uci.edu/ml/machine-learning-databases/",
"kddcup99-mld/kddcup.data.gz", sep = "")))
stream <- DSD_ReadCSV(con, take = c(1, 5, 6, 8:11, 13:20, 23:42), class = 42, k = 5)
stream
p <- get_points(stream, n = 1000, class = TRUE)
#Scale stream and read first 1000 in memory
ds.stream <- DSD_Memory( DSD_ScaleStream(stream, n = 2000),n = 2000)
p2 <- get_points(ds.stream, n = 1000, class = TRUE)
plot(ds.stream, n=1000, method="pc")
### prepare algorithms
algorithms <- list(Sample = DSC_TwoStage(micro = DSC_Sample(k = 100), macro =
DSC_Kmeans(k = 5)),
Window = DSC_TwoStage(micro = DSC_Window(horizon = 100), macro =
DSC_Kmeans(k = 5)),
`D-Stream` = DSC_DStream(gridsize = 5.8, Cm = 1.0), #Cm:density threshold
DBSTREAM = DSC_DBSTREAM(r = 0.7)) # r: The radius of micro-clusters
### cluster
for (a in algorithms) {
reset_stream(ds.stream)
update(a, ds.stream, n = 1000)
}
sapply(algorithms, nclusters, type = "micro")
for (a in algorithms) {
reset_stream(ds.stream)
update(a, ds.stream, n = 1000)
}
sapply(algorithms, nclusters, type = "macro")
##To inspect micro-cluster placement, plot the calculated micro-clusters on a sample data.
op <- par(no.readonly = TRUE)
layout(mat = matrix(1:length(algorithms), ncol = 2))
for (a in algorithms) {
reset_stream(ds.stream)
plot(a, ds.stream, main = description(a), type = "micro",method="pc")
}
par(op)
#assignment = TRUE, weight = FALSE
op <- par(no.readonly = TRUE)
layout(mat = matrix(1:length(algorithms), ncol = 2))
for (a in algorithms) {
reset_stream(ds.stream)
plot(a, ds.stream, main = description(a), type = "micro",assignment = TRUE, weight =
FALSE,method="pc")
}
par(op)
### evaluate
sapply(algorithms, FUN = function(a) {
reset_stream(ds.stream, pos = 1001)
evaluate(a, ds.stream, measure = c("numMicroClusters", "purity", "SSQ"), type = "micro",
n = 1000)
})
### evaluate macro-clusters
op <- par(no.readonly = TRUE)
layout(mat = matrix(1:length(algorithms), ncol = 2))
for (a in algorithms) {
reset_stream(ds.stream)
plot(a, ds.stream, main = description(a),type = "both",method="pc")
}
par(op)
sapply(algorithms, FUN = function(a) {
reset_stream(ds.stream, pos = 1001)
evaluate(a, ds.stream, measure = c("numMacroClusters", "purity", "SSQ"
), n = 1000, assign = "micro", type = "macro")
})
##### Session 2 Simulate real-time by D-Stream
library("stream")
con <- gzcon(url(paste("http://archive.ics.uci.edu/ml/machine-learning-databases/", "kddcup99-
mld/kddcup.data.gz", sep = "")))
stream <- DSD_ReadCSV(con, take = c(1, 5, 6, 8:11, 13:20, 23:42), class = 42, k = 7)
stream2 <- DSD_ScaleStream(stream, n = 1000)
plot(stream2, n=1000, method = "pc")
dstream <- DSC_DStream(gridsize = 4.3, gaptime = 10000L, lambda = 0.01)
#gridsize - size of grid cell
#gaptime - increased number of points after which obsolete micro-clusters are removed
#lambda is used in the fading function, range from 0-1, the larger the lambda, the lower the
weight of the historical data
update(dstream, stream2, n=200000, verbose = TRUE)
dstream
### evaluate micro
evaluate(dstream,stream, measure = c("numMicroClusters", "purity","SSQ"), type = "micro",
n = 1000)
###evaluate Macro
evaluate(dstream,stream, measure = c("numMacroClusters", "purity", "SSQ" ), n = 1000, assign
= "micro", type = "macro")