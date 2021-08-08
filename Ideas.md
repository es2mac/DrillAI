
## Possible next steps


- Bug: start new game in the middle of auto play might crash
    - If it doesn't crash, it seems to have hidden bots playing in background

- There seems to be a subtle bug of timer that's still running through end of game
    - or more specifically, if the game is done, and bot play is clicked again, then
      click new game, the moves list would be updated to be empty, but I can still
      click bot play to start playing correctly
    - I think the callback is still called, but there might be a race condition that
      causes it to not cancel the timer correctly?  Maybe the stop should be checked
      more aggressively, at every timer tick?

- Animation
    - Animate row clear
    - Animate garbage rise
    - Animate placing piece
        - Generate the move sequence from spawn to final position
        
- What can be animated?
    - Left/right move always instantaneous
    - Hard drop: maybe a fake one, where it's actually instantaneous but a blur flashes through?
        - Tetris Effect does a weighted springy motion
    - Line clear: 
        - When the piece drop, there could be an "explosion" or flash sequence,
          or immediately disappear leaving emptiness
            - Can do a flash only for clearing garbage lines
        - Then the higher lines fall down
    - Garbage rise:
        - It could rise slowly (linearly?) depending on how much more to rise
   
- Animation plan:
    - Stage 0: weighted piece fall
        - Animate whole field (including grid lines and ghost, but not play piece?)
        - I might need a flag in DisplayField to indicate whether a piece dropped, so I can bounce
        - One possible way to do this, though hopefully can find something easier: keep a state that is
          incremented each time onChange of new field with a piece drop, and use a custom
          modifier animating that state, in a way that it does a cycle over the value change of 1,
          like a GeometryEffect
        - Or, animate path, either way I need to know about the Animatable protocol
    - Stage 1: line clear and adds
        - Filled rows are still in data, but marked, and garbages are already added below
        - Need field rows to be able to draw more than 20 rows
    - Stage 2: clamp rows back together
    
        
    - Consider helping it with permanent/transcient states
    
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

- Maybe put field in a drawingGroup

- Maybe use MainActor for the view model update
    - The update logic might be improved

- Document GameState
- Document DigEnvironment

- More concrete types for where I'm using tuples to pass information around

- "Merge equivalent children" idea
    - Check popular nodes 2-step away from root and merge equivalent ones
    - What to do with the counts is an issue

- Command-line program to play through 100-line games
    - Then start collecting data
    - Problem:  Can't run under macOS 11...
    
- A way to control... so one can manually play?
    - On mac handling keyboard:
        https://stackoverflow.com/questions/61153562/how-to-detect-keyboard-events-in-swiftui-on-macos
    - On iOS, seems to need to custom-class the UIHostingController
    - On-screen control is the more orthodox option for iOS

- Rewind play steps


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



