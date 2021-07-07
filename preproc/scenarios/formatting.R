## setwd("~/research/iamup/mimi-page-2020.jl/preproc/scenarios")

prefix <- "rcp19_"

## Files are relative to 2020, and use decadal values.
## Convert to relative to 2015, and irregular timesteps.

for (filename in list.files("rcps", paste0(prefix, ".+", "\\.csv"))) {
    df <- read.csv(file.path("rcps", filename))
    df.2015 <- (df[df$year == 2010,] + df[df$year == 2020,]) / 2 # first row is 2010
    result <- rbind(cbind(year=2020, 100 * df[df$year == 2020, -1] / df.2015[, -1]),
                    cbind(year=2030, 100 * df[df$year == 2030, -1] / df.2015[, -1]),
                    cbind(year=2040, 100 * df[df$year == 2040, -1] / df.2015[, -1]),
                    cbind(year=2050, 100 * df[df$year == 2050, -1] / df.2015[, -1]),
                    cbind(year=2075, 100 * ((df[df$year == 2070,] + df[df$year == 2080,]) / 2)[, -1] / df.2015[, -1]),
                    cbind(year=2100, 100 * df[df$year == 2100, -1] / df.2015[, -1]),
                    cbind(year=2150, .5 * 100 * df[df$year == 2100, -1] / df.2015[, -1]),
                    cbind(year=2200, .5^2 * 100 * df[df$year == 2100, -1] / df.2015[, -1]),
                    cbind(year=2250, .5^3 * 100 * df[df$year == 2100, -1] / df.2015[, -1]),
                    cbind(year=2300, .5^4 * 100 * df[df$year == 2100, -1] / df.2015[, -1]))
    if (substring(filename, nchar(prefix)+1, nchar(filename)-4) == 'excess') {
        df.co20 <- read.csv("../../data/e0_baselineCO2emissions.csv", skip=3)
        combined <- as.matrix(result[, -1]) %*% (df.co20[, 2] / sum(df.co20[, 2]))
        df.rcp26 <- read.csv("../../data/rcps/rcp26_excess.csv", skip=2)
        ## Assume matches in 2020
        result <- data.frame(year=result[, 1], excess=(combined / combined[1]) * df.rcp26$rcp26_excess[1])
    }
    fp <- file(file.path("../../data/rcps", filename), 'w')
    if (substring(filename, nchar(prefix)+1, nchar(filename)-4) == 'excess') {
        cat("# Index: time\n\n", file=fp)
    } else {
        cat("# Index: time, region\n\n", file=fp)
    }
    write.csv(result, fp, row.names=F)
    close(fp)
}
