# NCAA-pool-entry-optimization
<img src = 'https://www.gamblingsites.org/blog/wp-content/uploads/marchmadnessprintablebracket.jpg'>

I hate losing March Madness pools as much as I love March Madness. And I've lost a LOT of pools. You probably wrestle with the same annual problem as I do, namely: where on the chalk-upset continuum should my bracket sit?

Ultimately, what matters is value. And since our goal is presumably to win money, value is best measured as ROI, expected value (EV), or similar. Given that, we need to figure out how to determine which picks -- or really, which set of 63 picks -- provide the highest average profit.

To figure that out, I built what amounts to a relatively simple model that sets up a fictitious (but realistic) pool, plays out the tournament thousands of times, scores the pool for each iteration, and looks at which brackets generate the highest ROI over the long-term.

### Data
As is often the case, getting good data is actually the hardest part here. We need to set the following assumptions:

* A distribution of our opponents' selections (i.e. how likely is a competitor to pick each team to win each round)
* Measures of the relative strength of each team, such that we can estimate the probability of teams winning any given matchup
* The payout structure for the pool

#### Opponents' selections
Right away, you can see this will be tough. We can assume that our fellow competitors will tend to select 1-seeds to win it all more often than 12-seeds, but certain 1-seeds are bound to be more popular. Further, our opponents are just as interested in maximizing ROI as we are...although they'll probably be doing so intuitively. For example, they'll probably be more likely to pick a long-shot overall winner if they pool is large, with a skewed payout structure.

A decent proxy for such a tournament is ESPN's ["Who Picked Whom"](http://fantasy.espn.com/tournament-challenge-bracket/2019/en/whopickedwhom) summary. ESPN runs a massive nationwide pool with millions of entries, with prizes only going to the top few entrants. I assume this works for other large pools (e.g. 1000 entrants), but I'd use these percentages with caution if you're applying this approach to an office pool with a few dozen participants. The incentive to pick wild upsets is much lower, and entries will tend to be more chalk-y.

#### Team strength
I'm a big fan of [Ken Pomeroy's web site](https://kenpom.com/index.php), and if you're here reading about NCAA simulation models on GitHub, chances are high that you are too. Ken maintains, among other things, efficiency ratings for all NCAA D1 basketball teams. These, along with his adjusted tempo statistic, can be used to estimate expected scoring margin, and (with a couple of additional assumptions) the probability of each team winning a given matchup. This [Reddit post](https://www.reddit.com/r/CollegeBasketball/comments/5xir8t/calculating_win_probability_and_margin_of_victory/) gives a pretty good summary of how to do just that.

Now, as much respect as I have for Ken, I have even more respect for the collective wisdom / efficiency of betting markets. (If you feel differently, then you should be using Ken's ratings to bet aggressively.) For that reason, I start with Ken's efficiency ratings but then make some subjective adjustments to force the calculated probabilities of each team reaching a given round to approximately equal probabilities implied by Vegas odds. If you want to just use Ken's numbers as given, you can take some comfort in knowing that his expected margins are often very close to the Vegas line.

#### Payout structure
Finally, something that we know for certain! It's important to contemplate the payout structure of the pool in question, because the optimal strategy might be very different for a winner-take-all pool vs. one that awards prize money to the top half of entries.

### Model
Like I said, the model itself is not too complicated, relatively speaking. It proceeds in the following steps:

1. Set basic parameters (e.g. num sims, num entries, scoring system, payout structure)
2. Import and pre-process data (e.g. import efficiency ratings, set up bracket, calculate win probability matrix, etc.)
3. Simulate the entire tournament n times
4. Create entries for k fictitious competitors using the assumed pick distribution
5. Score the k sheets for each of the n simulations and award prize money according to the selected payout scheme
6. Look at average payouts by sheet over all simulations, and pick the highest

There's a little more to it than that, but I'll leave it to the interested reader to go through the R code.

### Results
For the 2019 tournament, the table below shows the mean ROI associated with picking each team to win each round. Though this provides an interesting summary of modeled results, it doesn't really directly address the issue of how to fill out the bracket to maximize profit.

IMAGE HERE

COMMENTARY HERE

Instead of looking at it this way, I used the top 16 entries as provided by the model and entered them into DraftKings Sportsbook's $20 NCAA pool. The pool included somewhere in the neighborhood of 6,000 entries, with $20k going to the overall winner (and lesser amounts to lower places).

So how did the model do? Really well, actually! In fact, one of the 16 entries had Texas Tech beating Virginia in the final and was in first place overall with about 12 seconds left in the game (see below)...until De'Andre Hunter tied it with a 3-pointer. Thankfully, because I knew I had a great shot at winning the $20k going into the game, I laid of several thousand before tip so still came out ahead.

<img src = 'https://github.com/solaka/NCAA-pool-entry-optimization/blob/master/images/IMG_2211.PNG' width="250" height="440">

It's worth underscoring that the model didn't "believe" that Virginia beating Texas Tech was a particularly likely outcome. In fact, TT was considered a longshot to win the title (somewhere around 3%). But the model determined that they were picked infrequently enough by our competitors to make that a profitable selection, and it turns out to be right.

It's also worth reiterating the larger point that this model doesn't base selections on any kind of special insights about how likely different scenarios are. It's more like arbitrage...taking advantage of 'inefficiencies' in our competitors' picks relative to the likelihood of success of the various teams.
