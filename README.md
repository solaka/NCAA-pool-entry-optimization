# NCAA-pool-entry-optimization
<img src = 'https://www.gamblingsites.org/blog/wp-content/uploads/marchmadnessprintablebracket.jpg'>

I hate losing March Madness pools as much as I love March Madness. And I've lost a LOT of pools. You probably wrestle with the same annual problem as I do, namely: where on the chalk-upset continuum should my bracket sit?

Ultimately, what matters is value. And since our goal is presumably to win money, value is best measured as ROI or EV. Given that, we need to figure out how to determine which picks -- or really, which set of 63 picks -- provides the best return.

To figure that out, I built what amounts to a pretty simple model that sets up a fictitious (but realistic) pool, plays out the tournament thousands of times, scores the pool on each iteration, and looks at which brackets generate the highest ROI over the long-term.

### Data
As is often the case, getting good data is actually the hardest part here. We need to set the following assumptions:

* A distribution of our opponents' selections
* Measures of the relative strength of each team, such that we can estimate the probability of each team winning any given matchup
* The payout structure for the pool

#### Opponents' selections
Right away, you can see this will be tough. We can assume that our fellow competitors will tend to select 1-seeds to win it all more often than 12-seeds, but certain 1-seeds are bound to be more popular. Further, our opponents are just as interested in maximizing ROI as we are...although they'll probably be doing so intuitively. For example, they'll probably be more likely to pick a long-shot overall winner if they pool is large, with a skewed payout structure.

A decent proxy for such a tournament is ESPN's ["Who Picked Whom"](http://fantasy.espn.com/tournament-challenge-bracket/2019/en/whopickedwhom) summary. ESPN runs a massive nationwide pool with millions of entries, with prizes only going to the top few entrants. I assume this works for other large pools (e.g. 1000 entrants), but I'd use these percentages with caution if you're applying this approach to an office pool with a few dozen participants. The incentive to pick wild upsets is much lower, and entries will tend to be more chalk-y.

#### Team strength
