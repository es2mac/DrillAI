
## Possible next steps

- Race condition:  If a new game is started when the view model is in the middle of
  updating, then the visual will go out of sync and may even crash
    - Saw crash in getting next display field -- old display field was nearly cleared,
      then new field to try to match is unrelated.  Lucky that it causes a crash.
    - Possibly fix this when implementing view model action sequence with AsyncStream

- Bot play/pause button

- Fix all the SwiftUI previews, in due time

- Twist and slide moves
    - Implement SRS wallkicks
    - "Hinge" detection
        Check for 2x2 shape with only top left or right filled
        ```
        O _          _ O
        _ _    or    _ _
        ```
    - Only check from natural drop positions, and not hanging in midair

- Record game in-memory and long-term
    - Two seeds, history of move pieces
        - These are enough to programmatically recreate the game
    - Optionally, available piece sequence, clear counts, fields

- Show other info, e.g. step

- Add controls, e.g. replay history

- Animation
    - Placing piece
        - Generate the move sequence from spawn to final position
            - Might create an AsyncStream in the view model as a queuing system
              for movements
        - Hard drop flash
   
   
[Advanced SwiftUI Transitions](https://swiftui-lab.com/advanced-transitions/)
[Advanced SwiftUI Animations – Part 1: Paths](https://swiftui-lab.com/swiftui-animations-part1/)
[Advanced SwiftUI Animations – Part 2: GeometryEffect](https://swiftui-lab.com/swiftui-animations-part2/)
[Tweaking SwiftUI animations with GeometryEffect](https://nerdyak.tech/development/2019/08/29/tweaking-animations-with-GeometryEffect.html)
    

- My fancy-looking generator bot doesn't actually make things run on separate
  threads / concurrently
    - Printing out the thread in the actual work functions show this
    - Why was it previously showing ~140% CPU usage sometimes?
        - Suspect that it's the detached node deallocation
    - Maybe this doesn't matter much, because BCTS eval is too fast anyways
    
- Keep thinking about architecture

- Documentation
    - GameState
    - DigEnvironment
    - Everything

- More concrete types for where I'm using tuples to pass information around

- Rethink the treatment of typealias ActionVisits

- "Merge equivalent children" idea
    - Check popular nodes 2-step away from root and merge equivalent ones
    - What to do with the counts is an issue

- Command-line program to play through 100-line games
    - Then start collecting data
    - Problem:  Can't run under macOS 11...
    
- Can add sound? https://freesound.org

- A way to control... so one can manually play?
    - On mac handling keyboard:
        https://stackoverflow.com/questions/61153562/how-to-detect-keyboard-events-in-swiftui-on-macos
    - On iOS, seems to need to custom-class the UIHostingController
    - On-screen control is the more orthodox option for iOS
        - Direct touch manipulation / gesture makes the most sense

- Possible inspiration / different architecture: alpha-beta pruning & NNUE
    - https://github.com/glinscott/nnue-pytorch/blob/master/docs/nnue.md

- Another simple UCT implementation, for study and reference
    - https://github.com/dkappe/a0lite

- Another field rows animation and drawing strategy:
    - Only have nonempty rows, and each row has an index, updated
      appropriately.  This way we can just use the index to offset each row.
    - Custom transition for row disappearing, so the sequence goes: start with
      filled rows, remove filled rows, update index.


## Old items

- Training with data augmentation: horizontal flip (though this could be problematic, because SRS rotation system isn't completely symmetric) (update: it is symmetric for all but the I piece), and raising / lowering field garbages
- Implement finding slide moves and SRS twist moves



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



