
## Possible next steps

- Document GameState
- Document DigEnvironment
- Update this document



- Improve BCTS eval
    - Improvement to value: factor in garbages left, nonlinearly?
    - less garbages left: maybe better value + weighed more in the weighted sum
    - btw, rename to BCTSBot?
    - Maybe dynamic PUCT

- Bot can decide whether there's a clear winner yet if there's a move that
  is significantly pulling ahead on visit count
    - balance between clear winner vs. total count, if results not clear,
      want to go for longer, but if results are clear, can end sooner
    - some kind of formula, in the spirit of PUCT?
    - also a min time & max time for each new step
        - maybe time is more informative than search counts
        - use up max time when new best end state is seen?
  
- Really curious about the duplication issue in the tree: put down 2 pieces in
  different orders should really be the same, and if those are the most promising
  moves they'd uselessly compete with each other and have overlapping subtrees
    - Turns out it's generally 75~95% unique within each 10k bin
    - overall though 60%?

- Strange thing is that following the best path often don't get to the absolute
  best piece count, wonder if I should special-case those
    - Given enough reps though, it does seem to converge alright
    - Maybe when a new best is seen, I'd want to have a good amount
      of runs to solidify it
  
- Wonder if PUCT exploration constant should be dynamically adjusted
    - Set on tree, propagate to all nodes
    - constant of 2.5 seems about right for BCTSEvaluator, though it still
      struggles when there's no obviously good choices, and likes to go
      deep ignoring all others when it sees something
      
- Filter evalutation targets: In actual games we don't have infinite previews,
  so the depth of search is limited
    - give filtering closure?
    - directly specify max search depth?
    
- More concrete types for where I'm using tuples to pass information around


## The BCTS bot

- The BCTS bot got to a point that's pretty workable.
- It's not good in long games where it can't see the end state.
- It does well for small fields, say 10-line games.  In 10-line games, it'd often
  have difficulty at the start, then once it catches an end state, it dramatically
  zooms into it and finds better solutions along the way.  I think this may mean
  that the values I derived from BCTS is still not diverse enough to provide good
  signals balancing the exploration factors, and that giving end states a big
  boost helped.  More tweaking of the evaluation and PUCT might help.
- But I think ultimately I want to move to the DL solution sooner because it's
  more interesting, and I like the idea of an evaluation that is more insightful
  to the specific problem at hand, i.e. drill down fast.


## Old items

- Try in-memory model training
- Generate some data with BCTS method and feed to model, see what happens
- Training with data augmentation: horizontal flip (though this could be problematic, because SRS rotation system isn't completely symmetric) (update: it is symmetric for all but the I piece), and raising / lowering field garbages
- Implement finding slide moves and SRS twist moves
- Further debug performance
- Consider terminal nodes (field garbage count = 0).  This probably requires separating the concepts of "having children" and "have been evaluated". (Maybe store value in node as optional, non-nil means evaluated)


MCTS (my implementation, not exactly as commonly described):

- Start from root node, select best child until we find one that hasn't been evaluated
  - "Best" includes priors, and balances exploration & exploitation
  - Internally, this node is freshly initiated at this selection step
- Prepare this node for evaluation, and set up for possible future visits
  - Find all valid children
  - Based on the number of valid children, initiate children N, W
- Evaluate the node
  - Get value of this node, and set priors for its children
  - Backpropagate the value


Working thought:

- An NN model needs to be able to handle 0~5 previews when doing MCTS for a real game that has 5 previews.  Cases with more previews seems more important, but cases with less previews are used far more often in that type of search (if time permits).  In fact, if we often get down to 3 previews or fewer (tree depth >2), maybe it's reasonable to shrink the model to only handle fewer previews?  On the other hand, with very few or no preview, there shouldn't be enough information to know with any certainty whether the next few lines could be cleared quickly.  It's very situational.

- Value function.  The general idea is efficiency, "piece/line ratio."  One idea is that only garbage lines matter, don't reward clearing lines made with player pieces.
  - The NN should estimate future efficiency, but when doing tree search, the cumulative clear count should be taken into account too.  So far the most plausible idea is to take NN's value, assume it is the average of line clears over the next 14 (?) moves, take the moves and clears from root node to this node, and amend the average.

- For RL's early stage, maybe I could set up a simplified problem, say given N=7 pieces (i.e. play, hold, and 5 previews), try to clear as many lines as possible.  Increase N once it gets off the ground.


References:
- The most relevant reference is [MiniGo in Swift](https://github.com/tensorflow/swift-models/tree/master/MiniGo), as well as the [original MiniGo](https://github.com/tensorflow/minigo).
- [MCTS with Python explanation](http://www.moderndescartes.com/essays/deep_dive_mcts/), some interesting implementation details to think about.
- [Nice of medium posts](https://medium.com/oracledevs/lessons-from-alphazero-part-3-parameter-tweaking-4dceb78ed1e5) on AlphaZero.
- [El-Tetris](http://imake.ninja/el-tetris-an-improvement-on-pierre-dellacheries-algorithm/) [source code](https://github.com/daogan/tetris-ai/blob/master/tetris_ai.py) has some clarifications of hand-crafted features.



