
library(tidyverse)
library(tictoc)
library(stringi)

setwd(choose.dir())

write.excel = function(x,row.names=FALSE,col.names=TRUE,...) {   # function to copy object contents to clipboard
  write.table(x,"clipboard",sep="\t",row.names=row.names,col.names=col.names,...)
}

######################################
### SETTINGS #########################
######################################

num.sim = 15000
num.entries = 40000
pts.by.round = c(10, 20, 40, 80, 160, 320)

# DK payout
payout.structure = data.frame(hi = c(1, 2, 3, 4, 5, 6, 7, 9,  11, 13, 16, 21, 26, 31, 41, 61, 91,  136, 211, 376, 651),
                              lo = c(1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 60, 90, 135, 210, 375, 650, 1195),
                              pct = c(.20, .10, .07, .04, .02, .01, .007, .005, .004, .003, .0025, .002, .0015, .00125, .001, .0008, .0007, .0006, .0005, .0004, .0003))

# winner take all
#payout.structure = data.frame(hi = c(1),
#                              lo = c(1),
#                              pct = c(1))


######################################
### import KenPom ratings ############
######################################
ratings = read_csv("summary19 - modified for Vegas odds.csv")
# to create 'modified for Vegas odds' version, compared KP champ odds to Vegas champ odds (eyeballing other rounds)
# and attempted to raise or lower adjEM numbers to at least move probabilities closer to Vegas probs, if not agree with them

######################################
### establish bracket ################
######################################
KP.tourney.odds = as.data.frame(read_csv("KenPom bracket 2019.csv"))

# round KP's <.001 probabilities to zero
KP.tourney.odds[KP.tourney.odds == "<.001"] = 0      

# ensure that probabilities are numeric
for (i in 3:8){
  KP.tourney.odds[,i] = as.numeric(KP.tourney.odds[,i]) / 100
}

# check colSums
colSums(KP.tourney.odds[,3:8])

# set up bracket structure
East = c("1E", "16E", "8E", "9E", "5E", "12E", "4E", "13E", "6E", "11E", "3E", "14E", "7E", "10E", "2E", "15E")
West = c("1W", "16W", "8W", "9W", "5W", "12W", "4W", "13W", "6W", "11W", "3W", "14W", "7W", "10W", "2W", "15W")
South = c("1S", "16S", "8S", "9S", "5S", "12S", "4S", "13S", "6S", "11S", "3S", "14S", "7S", "10S", "2S", "15S")
Midwest = c("1MW", "16MW", "8MW", "9MW", "5MW", "12MW", "4MW", "13MW", "6MW", "11MW", "3MW", "14MW", "7MW", "10MW", "2MW", "15MW")

bracket = data.frame(Seed = c(East, West, South, Midwest))
bracket = left_join(bracket, KP.tourney.odds %>% select(Pos, Team), by=c('Seed' = 'Pos'))
bracket = bracket[!duplicated(bracket$Seed),]      # take the 1st team listed for play-in games...shouldn't matter come Thurs. anyway
bracket = left_join(bracket, ratings %>% select(TeamName, AdjEM, AdjTempo), by=c('Team' = 'TeamName'))


######################################
### calculate win probs ##############
######################################

KPlog5 = function(EM1, EM2, T1, T2){
  league.SD = 11    # appears to be KP assumption...see sample KenPom log5 calcs.xlsx or https://www.reddit.com/r/CollegeBasketball/comments/5xir8t/calculating_win_probability_and_margin_of_victory/
  league.tempo = 67  # appears to be KP mean tempo...see same as above
  
  tempo = T1*T2 / league.tempo
  margin = (EM1-EM2)*tempo/100
  prob.W = pnorm(margin, 0, league.SD)
  prob.W
}

# fill win.probs matrix with win probabilities in given matchups...note this assumes all games on neutral courts
win.probs = as.data.frame(matrix(NA, nrow=64, ncol=64))
colnames(win.probs) = 1:64
for (i in 1:64){
  for (j in 1:64){
    win.probs[i,j] = KPlog5(bracket[i, 'AdjEM'], bracket[j, 'AdjEM'], bracket[i, 'AdjTempo'], bracket[j, 'AdjTempo'])
  }
}

######################################
### sim tournament function ##########
######################################

sim.tourney = function(){
  
  R1 = 1:64
  
  R2 = c()
  for (i in seq(1, 63, 2)){
    tm1 = R1[i]
    tm2 = R1[i+1]
    winner = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)
    R2 = c(R2, winner)
  }
  
  R3 = c()
  for (i in seq(1, 31, 2)){
    tm1 = R2[i]
    tm2 = R2[i+1]
    winner = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)
    R3 = c(R3, winner)
  }
  
  R4 = c()
  for (i in seq(1, 15, 2)){
    tm1 = R3[i]
    tm2 = R3[i+1]
    winner = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)
    R4 = c(R4, winner)
  }
  
  R5 = c()
  for (i in seq(1, 7, 2)){
    tm1 = R4[i]
    tm2 = R4[i+1]
    winner = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)
    R5 = c(R5, winner)
  }
  
  R6 = c()
  for (i in seq(1, 3, 2)){
    tm1 = R5[i]
    tm2 = R5[i+1]
    winner = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)
    R6 = c(R6, winner)
  }
  
  R7=c()
  tm1 = R6[1]
  tm2 = R6[2]
  R7 = ifelse(runif(1) > win.probs[tm1, tm2], tm2, tm1)

  c(R2, R3, R4, R5, R6, R7)
}

######################################
### sim tourney and record results ###
######################################

tic()

sim.res = array(0, dim = c(64, 6, num.sim))
colnames(sim.res) = c("R1", "R2", "R3", "R4", "R5", "R6")
row.names(sim.res) = bracket$Team

for (sim in 1:num.sim){
  winners = sim.tourney()
  sim.res[winners[1:32], 'R1', sim] = 1
  sim.res[winners[33:48], 'R2', sim] = 1
  sim.res[winners[49:56], 'R3', sim] = 1
  sim.res[winners[57:60], 'R4', sim] = 1
  sim.res[winners[61:62], 'R5', sim] = 1
  sim.res[winners[63], 'R6', sim] = 1
}

toc()

# formulas to compare champ probabilities to KP's probs posted on web site
sim.totals = apply(sim.res, MARGIN=1:2, FUN=sum)
as.data.frame(-sort(-sim.totals[,4] / num.sim))


######################################
### read in pick distributions #######
######################################

pick.dist.raw = as.data.frame(read_csv("ESPN who picked whom 2019.csv"))
pick.dist = as.data.frame(matrix(NA, nrow=nrow(pick.dist.raw), ncol=ncol(pick.dist.raw)*2))

for (r in 1:nrow(pick.dist.raw)){
  for (c in 1:ncol(pick.dist.raw)){
    ct = (c-1)*2+1
    res = strsplit(stri_replace_last(pick.dist.raw[r, c], "#", regex="-"), "#")[[1]]
    res[1] = gsub('([0-9])', '', res[1])
    res[2] = pmax(as.numeric(gsub('%', '', res[2]))/100, 0.001)   # don't allow zeroes...have to assume at least a small number of entrants will pick every team in a large enough contest
    #pick.dist[r, ct:(ct+1)] = strsplit(stri_replace_last(pick.dist.raw[r, c], "#", regex="-"), "#")[[1]]
    pick.dist[r, ct:(ct+1)] = res
  }
}

colnames(pick.dist) = c("Team1", "Pct1", "Team2", "Pct2", "Team3", "Pct3", "Team4", "Pct4", "Team5", "Pct5", "Team6", "Pct6")
pick.dist$Pct1 = as.numeric(pick.dist$Pct1)
pick.dist$Pct2 = as.numeric(pick.dist$Pct2)
pick.dist$Pct3 = as.numeric(pick.dist$Pct3)
pick.dist$Pct4 = as.numeric(pick.dist$Pct4)
pick.dist$Pct5 = as.numeric(pick.dist$Pct5)
pick.dist$Pct6 = as.numeric(pick.dist$Pct6)

######################################
### create entry function ############
######################################

teams = read_csv("team names.csv")
pick.probs = data.frame(KP = bracket$Team)
pick.probs = left_join(pick.probs, teams)

paste("Number of team names not found: ", sum(is.na(pick.probs)))
Sys.sleep(5)

pick.probs = left_join(pick.probs, pick.dist %>% select(Team1, Pct1), by=c("ESPN" = "Team1"))
pick.probs = left_join(pick.probs, pick.dist %>% select(Team2, Pct2), by=c("ESPN" = "Team2"))
pick.probs = left_join(pick.probs, pick.dist %>% select(Team3, Pct3), by=c("ESPN" = "Team3"))
pick.probs = left_join(pick.probs, pick.dist %>% select(Team4, Pct4), by=c("ESPN" = "Team4"))
pick.probs = left_join(pick.probs, pick.dist %>% select(Team5, Pct5), by=c("ESPN" = "Team5"))
pick.probs = left_join(pick.probs, pick.dist %>% select(Team6, Pct6), by=c("ESPN" = "Team6"))

colSums(pick.probs[,3:8])
Sys.sleep(5)

create.entry = function(){
  E1 = 1:64
  
  E7 = sample(E1, 1, prob = pick.probs$Pct6)
  
  E6 = c()
  for (i in 1:2){
    indices = ((i-1)*32+1) : (i*32)
    prob.cond = pick.probs[indices, "Pct5"] - pick.probs[indices, "Pct6"]
    if(E7 %in% indices){
      pick = E7
    } else {
      pick = sample(indices, 1, prob=prob.cond)
    }
    E6 = c(E6, pick)
  }  
  
  E5 = c()
  for (i in 1:4){
    indices = ((i-1)*16+1) : (i*16)       # defines the 'slice' of the 64 teams under consideration for this line
    prob.cond = pick.probs[indices, "Pct4"] - pick.probs[indices, "Pct5"]   # prob of reach this round but no further...see sample calc for entry selection.xlsx for example...note that sample automatically scales probs to equal 1
    if(E6[ceiling(i/2)] %in% indices){    # if a team from this group is already picked to be in the next round...
      pick = E6[ceiling(i/2)]             # then it must be the pick for this round too
    } else {                              # otherwise
      pick = sample(indices, 1, prob=prob.cond)     # select a team based on defined probabilities
    }
    E5 = c(E5, pick)
  }  
  
  E4 = c()
  for (i in 1:8){
    indices = ((i-1)*8+1) : (i*8)
    prob.cond = pick.probs[indices, "Pct3"] - pick.probs[indices, "Pct4"]
    if(E5[ceiling(i/2)] %in% indices){
      pick = E5[ceiling(i/2)]
    } else {
      pick = sample(indices, 1, prob=prob.cond)
    }
    E4 = c(E4, pick)
  }  
  
  E3 = c()
  for (i in 1:16){
    indices = ((i-1)*4+1) : (i*4)
    prob.cond = pick.probs[indices, "Pct2"] - pick.probs[indices, "Pct3"]
    if(E4[ceiling(i/2)] %in% indices){
      pick = E4[ceiling(i/2)]
    } else {
      pick = sample(indices, 1, prob=prob.cond)
    }
    E3 = c(E3, pick)
  }    
  
  E2 = c()
  for (i in 1:32){
    indices = ((i-1)*2+1) : (i*2)
    prob.cond = pick.probs[indices, "Pct1"] - pick.probs[indices, "Pct2"]
    if(E3[ceiling(i/2)] %in% indices){
      pick = E3[ceiling(i/2)]
    } else {
      pick = sample(indices, 1, prob=prob.cond)
    }
    E2 = c(E2, pick)
  }   
  
  c(E2, E3, E4, E5, E6, E7)
}


######################################
### create entries ###################
######################################

tic()

entries = array(0, dim = c(64, 6, num.entries))
colnames(entries) = c("R1", "R2", "R3", "R4", "R5", "R6")
row.names(entries) = bracket$Team

for (sim in 1:num.entries){
  entry = create.entry()
  entries[entry[1:32], 'R1', sim] = 1
  entries[entry[33:48], 'R2', sim] = 1
  entries[entry[49:56], 'R3', sim] = 1
  entries[entry[57:60], 'R4', sim] = 1
  entries[entry[61:62], 'R5', sim] = 1
  entries[entry[63], 'R6', sim] = 1
}

toc()
# 10k entries = 8 seconds

# formulas to compare pick percentages to ones on ESPN site
entry.totals = apply(entries, MARGIN=1:2, FUN=sum)

rd = 1
pick.pct.test = entry.totals[,rd] / num.entries
sort(pick.pct.test, decreasing = TRUE)


######################################
### score entries ####################
######################################

payout.df = data.frame(place = 1:num.entries, payout = 0)
for (i in 1:nrow(payout.structure)){
  payout.df[payout.df$place >= payout.structure[i, 'hi'] & 
                  payout.df$place <= payout.structure[i, 'lo'], 'payout'] =
    payout.structure[i, 'pct']
}

tic()
pool.results = matrix(NA, nrow=num.sim, ncol=num.entries)

for (i in 1:num.sim){
  point.potential = t(t(sim.res[,,i]) * pts.by.round)
  for (e in 1:num.entries){
    pool.results[i, e] = sum(entries[,,e] * point.potential)
  }
  pool.results[i, ] = payout.df[rank(-pool.results[i,], ties.method = "random"), 'payout']
}
toc()
# 1000 sims, 1000 entries: 6.6 seconds
# 5000 sims, 5000 entries: 2.6 min
# 15000 sims, 40000 entries: 57 min


######################################
### find best entries ################
######################################

results.by.entry = colMeans(pool.results)

entries.sorted = entries[,,order(-results.by.entry)]   # most profitable listed first
entries.sorted[,,1]
entries.sorted[,,2]
entries.sorted[,,num.entries]

rank.select = 4
entry.select = as.data.frame(entries.sorted[,,rank.select])
as.data.frame(row.names(entry.select[entry.select$R1==1,]))
as.data.frame(row.names(entry.select[entry.select$R2==1,]))
as.data.frame(row.names(entry.select[entry.select$R3==1,]))
as.data.frame(row.names(entry.select[entry.select$R4==1,]))
as.data.frame(row.names(entry.select[entry.select$R5==1,]))
as.data.frame(row.names(entry.select[entry.select$R6==1,]))
