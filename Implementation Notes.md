

## Animation in SwiftUI

- Implicit animation can accomplish a lot.  Here the line clear animations are
  all implicit.
- Explicit animation used for shaking/sinking the field when a piece dropped.
  I'm not sure if there's an implicit way to do this, but explicit animation
  does give more control for which values should be animated, and for how long.
    - A particular issue solved by animating explicitly is that the shake's
      starting and ending positions are the same (the field sinks down then
      floats back up), so it seems there's no way to construct it as
      transforming value 1 to value 2, also it has a weird timing curve.

- An interesting problem occurred when I changed the way I sequence value
  updates in the game's view model.  When it was using hard-coded async-await,
  row clear explosions appear most of the time in the simulator.  But when
  rewitten using OperationQueue and dispatch, it doesn't show most of the time.
    - Having inspected a bunch of aspects e.g. switching dispatch to main back
      to using Task & @MainActor doesn't help.
    - Slowing down the timing makes the animations show much more consistently.
      So, my (reasonable IMO) guess is that OperationQueue introduces a bit
      more overhead than the new async/await, be it context switching or
      whatnot.  That's just a little too much and the black-box SwiftUI display
      & animation had to skip ahead some, at least for the simulator.  It
      remains to be seen how it'd work on an actual device, and whether it'd be
      worth trying to rewrite the thing with AsyncSequence.

- Some resources referenced:

[Advanced SwiftUI Transitions](https://swiftui-lab.com/advanced-transitions/)
[Advanced SwiftUI Animations – Part 1: Paths](https://swiftui-lab.com/swiftui-animations-part1/)
[Advanced SwiftUI Animations – Part 2: GeometryEffect](https://swiftui-lab.com/swiftui-animations-part2/)
[Tweaking SwiftUI animations with GeometryEffect](https://nerdyak.tech/development/2019/08/29/tweaking-animations-with-GeometryEffect.html)


## The BCTS bot notes

- The BCTS bot got to a point that's pretty workable.
- It's not good in long games where it can't see the end state.  In a 100-line
  game, it easily use over 500 pieces.  But at least it can finish.
- It does well for small fields, say 10-line games.  In 10-line games, it'd often
  have difficulty at the start, then once it catches an end state, it dramatically
  zooms into it and finds better solutions along the way.  I think this may mean
  that the values I derived from BCTS is still not diverse enough to provide good
  signals balancing the exploration factors, and that giving end states a big
  boost helped.  More tweaking of the evaluation and PUCT might help.
- In fact, I doubt I can do better (efficiency-wise) than it in 10-line games.
  Maybe 18.  I'd easily beat it in 100.
- But I think ultimately I want to move to the DL solution sooner because it's
  more interesting, and I like the idea of an evaluation that is more insightful
  to the specific problem at hand, i.e. drill down fast.  The wholesale borrowing
  of BCTS features and weights are just not that smart about it.  Looking at it
  play, it does have its aesthetics, a sense of flatness, than you can start to
  predict what it's gonna do and what kind of bad moves it tend to play.
- One more issue with the BCTS bot right now, is that it has too much information
  about the future.  It's not playing fair to humans who only has 5 preview pieces.
- Important note here is that I haven't shown that BCTS can't work, afterall, I've
  tweaked it and not done any reinforcement training on the borrowed coefficients
- From the human perspective, it's really not taking the avoidance of covering the
  next two holes seriously enough.

Other misc notes

- Strange thing is that following the best path often don't get to the absolute
  best piece count, wonder if I should special-case those
    - Given enough reps though, it does seem to converge alright
    - Maybe when a new best is seen, I'd want to have a good amount
      of runs to solidify it

- Wonder if PUCT exploration constant should be dynamically adjusted
    - The tree can keep it, and pass to nodes while traversing
    - constant of 2.5 seems about right for BCTSEvaluator, though it still
      struggles when there's no obviously good choices, and likes to go
      deep ignoring all others when it sees something

- Filter evalutation targets: In actual games we don't have infinite previews,
  so the depth of search is limited
    - give filtering closure?
    - directly specify max search depth?


## Tree duplications

- Really curious about the duplication issue in the tree: put down 2 pieces in
  different orders should really be the same, and if those are the most promising
  moves they'd uselessly compete with each other and have overlapping subtrees
    - Turns out it's generally 75~95% unique within each 10k bin
    - But 10k bin is kind of arbitrary, if I keep everything, overall the
      duplication % seems to keep increasing as more searches are done, can drop
      to only 60% or so unique values (that is, of 100 sent out for eval, only
      60% of those are unique, the other 40% are duplications).
    - Not sure if trying to optimize this is meaningful.  Maybe in the case
      where evaluation is much slower than tree operations (for BCTS, it's not),
      it'd be worth keeping a cache.
    - Related note, tree search is surprisingly taxing.  Optimizing the vDSP
      arrays allocation should've helped a lot.  (although I do wonder if a
      single-pass, plain code calculation of action values could in fact be
      faster than the vDSP calls.)
    - An idea that I'm not sure has prior art for:  Merging equivalent nodes.
      Seems like a pretty reasonable idea.  If we start from the root, look at
      the first couple most popular branches, and they have equivalent nodes
      one level down, then maybe we could cut one of them, either merging the
      trees or just break off the smaller one (just redirecting one of them
      might not result in the right traversal behavior if the backprop doesn't
      go through both).  Though it's hard to think through whether this works,
      because the subtree that has its branch cut would look less promising but
      that may not be the case.


## Tree's node search finding evaluated nodes

- An attempt to make the tree search for wider nodes -- When the search finds
  an evaluated node, the tree directly propagates a visit count and same value.
  The increase in visit count should decrease its "exploration" score, and the
  same value keeps the "exploitation" score constant.  But since a terminal
  state tends to have good value, my worry was that it's make this "trunk" that
  much stronger.
- I tried to change the logic to:  In each batch (e.g. 32) of finding nodes to
  evaluate, for each evaluated node I find, I add a virtual count that is
  reverted once the batch is done, and propagate the old value just once for
  that evaluated node.
    - Surprisingly, the end-games became erratic, I assume it's because the
      terminal node is losing out on visit counts, because it has no children.
    - So in the end, I scratched the idea.
  

## Coordinating two async tasks

- In trying to coordinate between the tree and evaluator, I went through all
  of the new async/await categories.
- Sequentially with await was simple enough, though did not try cancel mechanism.
- Tried using async let, but is somehow still an experimental feature.
- Creating task groups using withTaskGroup doesn't work well with what I want,
  and actually hit a memory leak issue.
- Finally, with unstructured concurrency, keeping reference to two tasks, and
  the main loop being just an infinite while loop, it actually worked quite well.


## Large tree deallocation

- Ran into deallocation performance issues with large trees, when I advance to
  a child node.  Surprisingly, it can hold up the MCTSTree quite a bit, halting
  for noticeable seconds (or even tens of seconds).
- Through educated guess and later instrument profiling, I did find that dealloc
  was the problem.
- First attempt to ameliorate the issue was to have a "trash can" that releases
  2x the amount of nodes that I create.  This requires disassociating the child
  node that I advance to, otherwise it'd unnecessarily do the releasing for the
  active tree.  I put the old root in, and process each node in the bin by
  unwrapping & adding all the non-nil children to the bin.  This does solve the
  problem, but with noticeable performance hit.
- Second attempt was to try throw the deinit sequence to a low-priority background
  queue.  And it works!  Although the memory seems to come down very slowly,
  or not coming down while the new tree is still growing, which I presume is
  partly because of the low priority.  But the performance is great, and the
  memory does eventually get released.
    - Turns out bumping up priority to utility and release is just fine.
    ```
    TaskPriority raw values:
    9  background
    17 low
    17 utility
    21 medium (default)
    25 high
    25 userInitiated
    ```


