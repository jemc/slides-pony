
![LFNW-start](http://i.imgur.com/oAfZSvL.png)

---

![Pony](img/horse.png)

# Pony
## An Actor Language For
### Provably Safe Lockless Concurrency

---

## Who Am I?

![jemc](img/jemc.png) ![cb](img/cb.png)

### Joe Eli McIlvain - Citrusbyte

https://github.com/jemc - https://citrusbyte.com

These slides on GitHub: https://github.com/jemc/slides-pony

---

## Concurrency

### What is it?
### Why do we want it?
### Why do we fear it?

----

## Concurrency

### What is it?

%% So, what is concurrency?

%% Concurrency is having multiple tasks that are being executed in a disjoint, overlapping way.

Multiple tasks executed in a disjoint, overlapping way

%% Note that these tasks can be executed in *parallel* on multiple processors at once *and/or* *scheduled* into arbitrary slices of time on one or more processors.

Can be in *parallel* and/or *scheduled*

%% When we're talking about concurrency, we just mean that we're not sure when each task is running relative to any other - they could be running in parallel, or they could be running in some unknown, possibly interleaved sequence.

Relative order of execution is unknown

%% We just don't know, and concurrent code is code that operates under this paradigm of not knowing this.

%% To be clear, each *task* is a linear sequence of operations with a well-defined order, but the *timing* of the operations in a task *relative* to those in the *other* concurrent tasks is arbitrary and undefined.

----

## Concurrency

### Why do we want it?

%% So, why do we want concurrency?

%% Well, it turns out that just prepping our application for concurrency isn't enough to get any *direct* benefits, though as we discussed, it allows our code to be run in a *parallel and/or scheduled* way, and *that* in turn can give us some very important benefits:

Concurrency alone isn't enough, but...

Running our code in *parallel* can give us:

* scalability %% We want to be able to add more processors to get proportionally more throughput - that's scalability.

* efficiency %% We don't want to have any idle processors, as that would be inefficient - we want to put all of our processors to work for efficiency.

----

## Concurrency

### Why do we fear it?

%% So, why do we fear concurrency? - what's the problem?

Non-determinism in the order of events

%% Essentially, with concurrency, we want to be able to write applications where we don't know the order in which everything is happening, but we can be sure that the final result is always correct.

%% This may sound a bit difficult, because it is. Arbitrary relative timings are a type of *nondeterminism*, and we want our overall application to be *deterministic*.

%% Now, we can easily allow order-nondeterminism where it doesn't matter. For example, if I ask you to go get groceries, clean the bathroom, and finish painting the shed, I probably don't care what order you do those things in, as long as they each get done.

%% However, if I ask you to go get groceries, deposit the paycheck, and pay the rent, the order in which you do these things might matter a great deal, depending on how much money is in our checking account.

%% Depending on how we structure our code and our concepts, the order-nondeterminism of concurrency can lead to subtle bugs that are difficult to reason about, reproduce, and test for. Here are some broad categories of concurrency bugs that we encounter:

Can lead to subtle bugs:

* data race %% data race one or more tasks access the same data in an undefined order, where one or more order possibilities leads to incorrect behavior.

* non-atomicity %% non-atomicity a conceptually atomic operation in one task is interrupted by another task, where the "middle" state that was not considered by the programmer leads to incorrect behavior in other tasks.

* deadlock %% deadlock interdependent tasks that are *blocking* (that is, waiting) for data or signal from eachother are mutually unable to make progress.

----

## Concurrency

### So how do we stay sane?

%% Given that we want concurrency, but dealing with concurrency can bring about these problems, how do we go about creating concurrent applications that we can be confident about?

Embrace a structured approach

%% Well, we need to embrace a structured approach to concurrency, where that structure brings some sanity and reason back to the jumble of nondeterminism that we'd otherwise be faced with.

%% In other words, we want to impose some strategic limits on ourselves and our code in order to limit the possible states of the resulting concurrent system.

%% So let's take a look at some of the structured approaches and conventions that we see out there...

---

## Synchronization

> Wherever my tasks share state with eachother, I can synchronize access to that state appropriately to avoid concurrency bugs.

----

## Synchronization

### How does it help?

%% So, how does it help?

Use locks to restrict the relative order of events

%% Using synchronization primitives like locks, mutexes, monitors, and semaphores allows us to impose *restrictions* on the relative order of *specific groups* of operations within concurrent tasks.

Blocks the task instead of violating the restriction

%% Effectively, these primitives force the tasks to *wait* (or *block*) for availability where they would otherwise plunge ahead and violate the given restrictions.

%% If planned appropriately and effectively, these restrictions can prevent the kinds of concurrency bugs we highlighted.

%% However, let's take another look at what synchronization is actually doing to our applications.

----

## Synchronization

### Reduces Concurrency

%% Synchronization *reduces* concurrency

Synchronized operations become non-concurrent

%% We've said that synchronization primitives allow the programmer to impose *restrictions* on the order of specific groups of operations, and we've also said that *concurrency* is the paradigm of not knowing the order of operations.

%% So, we see that synchronization works by allowing us to selectively *prevent concurrency* of certain operations.

%% As an extreme example, note that if we use a common mutex to synchronize the entire block of code for each concurrent task - so they're all using the same single global lock, and the entire tasks are synchronized - effectively, at this point there is no concurrency left at all - the mutex will force our tasks to be run sequentially instead of concurrently.

%% Now, that was indeed an extreme and contrived example, but we can see that in less extreme cases, it behaves the same way - the more synchronization we introduce in our tasks the more they end up waiting around, and the more we *reduce the degree of effective concurrency*

More synchronization => less concurrency

%% In this way, synchronization is more of a *workaround* for concurrency than a safe pattern of concurrency, and the more we use synchronization the more we will lose the benefits concurrency gives us.

%% A familiar example of over-synchronization is the Global Interpreter Lock (or GIL) found in the reference implementation of Ruby, in which *almost* all of the operations of the interpreter are synchronized by a single global lock, which severely reduces the actual concurrency that is possible using Ruby Threads - it's worth noting that the competing Ruby implementations, Rubinius and JRuby, improve on this strategy by using many fine-grained locks instead of one single global lock, so that some operations may be concurrent with some others - because they're not contending with the same lock.

----

## Synchronization

### is Error Prone

Lose as little concurrency as possible by being precise

%% So, to avoid losing too much concurrency to over-synchronization, we want to use synchronization primitives in a precise, detail-oriented way - synchronizing as little as is necessary to be safe - if we go back to our earlier example of Ruby's Global Interpreter Lock and the work in Rubinius and JRuby to separate this locking into more fine-grained locks, this is basically what we're talking about - more precision helps us to keep more opportunities for concurrency while still remaining exclusive where it counts.

%% However, in many cases this work is non-trivial, and even when done, understanding and maintaining it often entails a lot of additional cognitive complexity - thinking about all these locks, the circumstances under which you need to invoke each one, and the circumstances under which the total "interlocking" system might *deadlock* or otherwise behave badly - it gets to be quite a lot for a human (or a tool) to reason about.

More precise synchronization => more cognitive complexity

%% In essence, the more precisely we use synchronization (the finer-grained locks we use), the more difficult it becomes to reason about possible outcomes and the more likely we are to cause or fail to prevent concurrency bugs

Mo' concurrency => mo' problems

%% Regrettably, using synchronization with concurrency creates a situation where the more performance-optimal our code becomes, the more difficult it becomes to understand and maintain.

%% This is a terrible tradeoff, and grappling with it in this way is one of the main reasons why we're all afraid of concurrency.

%% So let's move on to another approach:

---

## Share Nothing

> If my tasks share no state with eachother, then safe concurrency is trivial.

----

## Share Nothing

### Why is it safe?

%% So why is it safe?

We get bugs when we share state,

So let's not share any state.

%% Well, The concurrency bugs we highlighted were all related to the interdependence of concurrent tasks - put another way, we get problems when we share state between tasks.

%% So, if we want to avoid the problems associated with synchronizing access to shared state, one trivial remedy is to avoid shared state altogether.

%% And indeed, when you can pull it off, this works *beautifully* - it scales perfectly because there is no relationship at all between the tasks, so there's no possibility of a bottleneck as you scale.

* no interdependence

* no communication

%% If our concurrent tasks are truly independent from one another, the nondeterminism of relative timings doesn't matter - that is, every possible order of events is correct behavior, because the tasks don't care about eachother at all.

----

## Share Nothing

### Advantages

* always safe
* easy to reason about
* easy to migrate between distinct machines
* scales perfectly

----

## Share Nothing

### Disadvantages

* only applies to tasks that can be made independent
* breaks as soon as you need to share something

---

## Share Immutable State

> If my tasks share only immutable state with eachother, then safe concurrency is trivial.

----

## Share Immutable State

### Why is it safe?

We get bugs when we share mutable state,

So let's not allow any mutation of it.

%% With some more consideration, we see it's not quite necessary to prohibit all sharing - rather it's sufficient to make sure that anything we do share is immutable - that is, guaranteed to never change.

%% If the data in the shared state is guaranteed to never change, then any task can read from it at any time and always see the same data.

%% There's no need to synchronize because a read operation will have never have any influence over the outcome of any other read operations.

* immutable data structures

* frozen objects

%% These nice properties - as well as others - make immutable data structures a popular choice for shared data - as long as it's immutable, there are no concurrency bugs to worry about.

----

## Share Immutable State

### Advantages

* always safe
* easy to reason about
* provides a way to share global data
%% giving in to the restriction that it can't be changed

----

## Share Immutable State

### Disadvantages

* can't migrate between distinct machines without copying data
* only applies to tasks that can be made otherwise independent
* breaks as soon as you need to share something mutable

---

## Transfer Isolated State

> If I can transfer exclusive access to a given state object from task to task, then the one task that can reach the state object at any given time may safely mutate it without violating concurrency safety.

----

## Transfer Isolated State

### Why is it safe?

We get bugs when we share mutable state,

So let's share it indirectly, *across time*.

%% Let's talk about what we mean when we say isolated - isolated state is only accessible from one task at a time, so it is not *really* concurrently shared.

%% When tasks are implemented as threads, this is sometimes called *thread-ownership* - the state object is held exclusively by a single thread, its owner - and no other thread it touch it.

%% This is clearly safe, but without sharing, it doesn't solve the original problem.

%% We can't share isolated state among multiple tasks at once, but we *can* share isolated state *across time* by securely transferring it from one task to another - this is sometimes called *message passing* or *transferring* thread ownership.

* "thread ownership"

* "message passing"

%% When I say securely transferring, I mean this - if we can guarantee that the original task doesn't hold on to any dangling references to the transferred state object, then it is still isolated when it reaches the next task - but if even a single reference is retained in the original task - sometimes called a *leaked* reference - all safety goes out the window, because both tasks have access to the same mutable state object at the same time.

%% So this method usually requires strict discipline to avoid leaking references, or language support to check and enforce that no references are leaked.

----

## Transfer Isolated State

### Advantages

* easy to reason about
* no mutability restrictions
* compatible with zero-copy optimizations

----

## Transfer Isolated State

### Disadvantages

* state is not truly shared - no concurrent access
* requires careful discipline (or language support)

---

## So what should we choose?

* ### A. Synchronization
* ### B. Share Nothing
* ### C. Share Immutable State
* ### D. Transfer Isolated State

----

## All of the Above
### (Except Synchronization)

%% Each of these paradigms has its advantages and disadvantages, and they each have their place in our applications - so why should we have to choose?

%% However, remember that Synchronization was not a safe pattern for concurrency, but rather a *workaround*, a way to *reduce* concurrency where we needed to - the other options are sort of workarounds as well, each in their own way, but note that none of them require waiting around for access to shared state, which Synchronization does.

%% We want to maximize concurrency, so let's leave Synchronization behind for now, and see if we can create our applications without it.

----

## So what do we want?

Easy to use the safe patterns

%% We want to use tools and conventions that make these safe patterns easy to use - programmers are lazy, so we have to make it easy to do the right thing or we'll mostly choose to do the wrong thing.

Verify safety by verifying the patterns

%% In fact, let's take it a step further and say that we never want to ship an application that isn't concurrency safe. If we verify and *enforce* the safe patterns, then we can write highly concurrent applications while remaining fully confident in their safety.

Clear and explicit - no guesswork

%% Since we're mixing and matching the safe concurrency patterns, we also want to make it clear to our tools and to ourselves which patterns we are using for any given part of our code. For example, no human or tool that's reading our code should ever have to guess whether a given state object is intended to be *immutable* or *isolated*.

%% Explicit clarity of intent will keep our applications easy to reason about as their behaviour becomes more complex.

Clean, consistent syntax and rules

%% Furthermore, the way we show our intent should be ubiquitous and uniform, with a clean, consistent syntax, and simple rules for understanding what that syntax means.

---

## Enter Pony
### A Language for Provably Safe
### Lockless Concurrency

http://www.ponylang.org/

https://github.com/ponylang/ponyc

----

## Enter Pony
### A Young Language

%% So, before we get too ahead of ourselves, I wanted to give a quick disclaimer.

%% Pony is an emerging technology - it's a young language that's changing every day - it's not yet mature, but it's also not theoretical - it's a real language with a real compiler and runtime, and it's ready to run real applications.

%% Pony was designed and created by a handful of academic folks in England who have given it a really solid foundation - if you're as interested as I was in how this all works, you can read the academic papers online and get into the proofs and details.

%% I started learning Pony about a year ago after reading the paper on Pony's message-passing per-actor garbage collector, which got me interested enough to give the language a try. Since then I've been writing libraries and helping others learn to use Pony. Recently I was asked to join the core team to help guide the future of the language and the community.

%% To me, this is a really exciting time to be involved with this language.

----

## Enter Pony
### A Static, Compiled Language

Static analysis enforces concurrency patterns

Understands your application without running it

%% Pony is a static, compiled language. The compiler is the tool that statically analyzes and enforces the safe concurrency patterns we've been talking about - in case you're not familiar, "static" just means that it doesn't have to run your code to understand it.

Concurrency safety without cost of runtime checks

%% If Pony were a dynamic language (as opposed to static), it wouldn't start to understand your code until it was running - This effectively means it would need to run your code surrounded by a bunch of runtime checks to ensure concurrency safety at every step of the way, effectively slowing down your code as well as making you add a bunch of guard code to "rescue" concurrency violation errors if they do happen, because you wouldn't know ahead of time if those violations were there or not.

%% Doing this analyis statically instead allows your application to only spend its time doing only "business logic", and not checking whether its safe to read from or write to any given reference - it can safely plunge ahead with the assumption that the safety of whatever its about to do was verified at compile time.

High performance

%% In terms of performance, Pony code should be comparable to code written in C or C++, since it compiles down to a minimal LLVM representation that looks a lot like what you might see produced by the `clang` compiler (which compiles C and C++ code using LLVM).

----

## Enter Pony
### A Type-Safe Language

%% Type safety is also part of Pony's static analysis.

Yeah, I know, `*`*groan*`*`

%% Now, like perhaps some of you, I groan a little bit here, because I am totally comfortable writing robust code in a "type-less" language like Ruby or Python, and I've often argued that *type-safe* languages usually create more hassle for the programmer than they solve real problems.

But concurrency safety makes it worthwhile

%% However, in Pony, the concurrency patterns we've been talking about are *part of the type system*. This is a big deal because while it's pretty easy to intuitively understand and reason about what *types* of objects you're dealing with in each part of a well-written application, it can be much harder to understand and reason about how those objects might be accessed concurrently, and having those assumptions be implicit means that you or others will inevitably get confused at some point as to what's going on and who can access what and whether waiting for a lock is needed.

Some nice syntax sugar makes it "not so bad"

%% In this case, since we're already doing a lot of static analysis to ensure concurrency safety, I think it's reasonable and helpful to go for type safety as well, and Pony does a pretty good job of not making this too much of a headache for the programmer.

----

## Enter Pony
### An Object-Oriented Language

%% Pony is object-oriented.

Functional programming languages are cool,

%% Now, as concurrency becomes more and more important in our applications, a lot of people are turning to functional languages to solve these problems we've been talking about - usually with a focus on immutable data structures.

But objects are nice and natural abstractions

%% Functionally pure languages can be quite satisfying to work with, but if you're like me, you start to miss the convenient abstraction of objects. There's a good reason for this - objects and interfaces are really very natural abstractions for mirroring how humans think about solving problems - well, maybe not *mathematicians*, but they're a special case of human, I think - most of us tend to think in terms of objects, and there's something to be said for making our code look more like our thoughts.

%% Functional languages eschew objects because they aren't referentially transparent, making it difficult to enforce safe patterns.

In Pony we can have them *and keep* many benefits of FP

%% However, in Pony, we can get *many* of the same benefits using objects because both the humans and the tools reading the code have complete information about how our object reference graphs are structured, *including* the concurrency patterns each part of the graph is restricted to.

And you can still use functions when it makes sense

%% Now, if you're heavily into the functional programming paradigm, this slide probably didn't convince you to embrace objects again. But that's okay, because you can write functions in Pony too - essentially they're methods on a what Pony calls a "primitive", where the receiver is an object that has no state and is not allocated - so, not really an object at all in the traditional sense.

----

## Enter Pony
### An Actor Language

%% Pony is an actor language.

%% This means that instead of expressing concurrency in terms of explicit threads, fibers, processes, or co-routines, we use a higher-level (and more object-oriented) abstraction called actors.

Pass messages, trigger behaviours

%% In short, actors are objects which don't provide synchronous access to any of their internal state - that is, you can't call an actor method and expect a return value - instead you pass it an asynchronous message that triggers a corresponding behaviour when the message is received - but you don't know or care when that is, and you don't spend any time waiting around for a result.

Messages have causal order, not sequential order

%% Essentially, when we think about actors, we shift our paradigm from thinking about sequences of actions and instead think our program in terms of causes and effects - forcing ourselves into this paradigm shift in turn makes it easy for the runtime scheduler to execute tasks in parallel - more broadly, any task can be scheduled to execute at any time, *provided that* the effect does not precede the cause - this is the rule the Pony runtime works under - we call this "causal message order", and I want to come back to this topic in a later slide, because it's a bit more important than it might sound on the surface.

Scheduled by the runtime

%% Again, we give these actor declarations to the Pony compiler, defining their *behavior* for receiving each kind of message they can handle - and then, in the Pony runtime - the execution of the program is just the unfolding of these messages over time from initial conditions, and from external input. The runtime takes care of scheduling execution in an efficient way (using a "work stealing" algorithm) over a fixed number of system threads (usually equal to the number of cores on your machine), so you never have to worry about spinning up your own threads, or anything like that.

No synchronization primitives (lockless)

%% So, coming back to locks - because our actors follow the safe concurrency patterns that we've been discussing, there's no need for any synchronization - and indeed there are no synchronization primitives in Pony - Pony applications are lockless by nature.

No blocking operations

%% In fact, there are no blocking operations at all - so your actors are never waiting around within a behaviour, unable to receive new messages.

---

## Pony Paradigms

----

## Pony Paradigms
### No Blocking!

Blocking is an anti-pattern

%% As I mentioned in the last slide, blocking in Pony is an anti-pattern. In fact, it's not even possible unless you're using the *FFI* to call some native function that might block.

%% Some other actor-oriented languages include a *blocking receive* feature - that is, they have a way to *wait* for a specific response from another actor (or perhaps, a timeout event if this response doesn't come within some expected period of time) - Pony doesn't have this, but it's often requested by users coming from other languages - so what gives?

If we allowed blocking it would either:

* make our actor go idle when there is still more work for it to do

* make our actor behaviours non-atomic (and accumulate memory)

%% Well, such a feature is usually implemented in one of two ways - the most straightforward way is to just let the actor block, preventing it from handling any more messages while it's tied up and waiting for that *one* special message (which again, may never arrive or may take arbitrarily long to arrive) - this means your actor may spend a lot of time idle when in fact there are more messages for it and more work to do - in fact, this makes our actors start to look a lot like synchronization primitives, which is what we were *trying* to get rid of with this system.

%% So, this obviously isn't ideal, and there's a slightly more clever way to do this - while we wait for this actor to receive that *one* special message (and then take some arbitrary followup action based on the result), we *allow* that actor to handle *other* incoming messages as well, each according to their appropriate behavior - essentially, this means we capture a bit of state that holds the info about what message we're waiting for and what we're going to do when we get it, and then every time a message comes in we compare it to that list of special messages that we're waiting for and see if we can find a match - if we do, we can finish the corresponding followup action and clear out that bit of state - otherwise, the message is one that we have a defined behaviour for, and we just execute that behavior.

%% Now, this has a couple of problems - as you might have guessed, in a highly active system, those *tiny* little bits of state can quickly add up to an arbitrarily big chunk of memory - now, we could put some kind of a limit on this memory, but that means when we reach that limit, we're back to simple waiting again, just like before - the *other* problem is that our actor behaviours are no longer atomic - that is, actor behaviours in Pony act like *atomic transactions* over the actor's internal state - we have some current state, the message comes in, we execute the corresponding behaviour fully, and now that state might look a bit different if the behaviour involved changing some of the fields - if behaviours weren't atomic it means that at the start of a behaviour, you could check the value of some internal actor field, decide what to do based on that value, call a method that somewhere deep down in its stack chooses to spend some time blocking, then the internal field that you checked before and made that decision about now has an *undefined value* - that is, since you called a blocking method and the actor had a chance to handle other messages, that field may have been changed by those messages - in a world where methods can block and actors keep right on running, you can't call confidently call a method without worrying about whether the rug is going to be pulled out from under you.

%% To make our programs easy to reason about, we reject both of these solutions, and we choose to never be idle and always be atomic - and if we ever *do* need to store some state to mark that we are waiting for some special message, we do it in a field of the actor, and we use explicit logic to make it obvious what happens while we wait - the ramifications of waiting in a concurrent program can be severe, and if we ever are waiting for something, we *want* those ramifications to be in our face, staring us down and challenging us to find a different pattern, or at least acknowledge the engineering tradeoffs of the pattern we've chosen.

We choose never-idle, always atomic.

%% This brings up another critical point about concurrent programming - any time you try to hide the asynchronous nature of it - to make the asynchronous appear synchronous - you disguise the truth and prevent the critical thinking required to make good decisions - it's like going through a store and tearing off all the price tags, to the point that you can't tell which items are costly and which ones are cheap - we want simplicity, but we don't want to get it by just sweeping the complexity under the rug - we want to distill the essence of the problem and bring it to the surface, where we can make smart choices about how to solve it - and that's what we try to do with concurrent programming in Pony - we don't make the costly appear cheap, we don't make the risky appear safe, and we *don't* make the asynchronous appear synchronous.

We choose to never make the asynchronous appear synchronous.

----

## Pony Paradigms
### Causality

%% As we started talking about near the end of the last slide, our goal should be to find the essence of a problem and shift our paradigm to focusing on that - so what paradigms do we need to revise when we're thinking about concurrency?

----

## Pony Paradigms
### Causality

Forget total order, embrace causal order

<code>
```ruby
      (events over time)
<-- A ---- B ---- C ---- D -->
```
</code>

%% Well, one paradigm that needs some adjustment is our basic conception of time and the order of events - when we think about events happening over time, we often think about them happening on a single timeline - that is, event A happens at this point on the timeline, then event B happens, then event C, then D, and so on - looking at this diagram, try to think about these events like beads on an abacus - I can slide them back and forth, but because they're on the same timeline and I can't "slide them" past eachother, A will always come before B, and so on - we have events sorted into this total order, and it's all very definite and clear-cut and we can easily trace our way through the timeline - however, if we want concurrency, this turns out to be a bit *too* definite and clear-cut.

----

## Pony Paradigms
### Causality

Forget total order, embrace causal order

<code>
```ruby
<---- A --------------------->
.                            .
<--------------------- B ---->
.                            .
<---------------- C --------->
.                            .
<-- D ----------------------->
```
</code>

%% Going back to my proposed definition of concurrency from the first slide - I said "Concurrency is having multiple tasks that are being executed in a disjoint, overlapping way." - I also said that the "relative order of execution is unknown" - so, we introduce concurrency to our program, and all of a sudden our one timeline becomes four timelines - and by chance, maybe event D now happens first, then perhaps A, then C, then B - each one of the events is now happening on its own timeline, and can be slid back and forth freely on the timeline based on arbitrary circumstances that we have no control over or knowledge of - and now they can "slide past eachother" there is no longer any definite total order of events - everything is happening at once - that's concurrency.

%% In some cases, this is just fine - if our tasks don't depend on eachother, then we don't really care about the order of events - with no interdependency, any order of execution still gives a correct program - but what if some of our tasks *do* depend on eachother?  If we can't have a *total order*, we *at least* want to have some way to mark these dependencies and guarantee, for example that A happens before B, and C happens before D.

----

## Pony Paradigms
### Causality

Effects follow causes

<code>
```ruby
<---- A --------------------->
.      \                     .
<------ B ------------------->
.                            .
<---------------- C --------->
.                  \         .
<------------------ D ------->
```
</code>

%% Well, this is where *causality* comes in - the rule that, in the time dimension, causes must happen before their effects, or that effects follow their causes - this definition of causality comes from physics, but it's also a very natural, even obvious conclusion for us to come to - if me dropping a bowling ball caused my foot to get hurt, then I must have dropped the ball before I felt the pain - if these events happened in the opposite order (I felt the pain, then I dropped the ball), you wouldn't let me say that dropping the ball *caused* the pain - that wouldn't make any sense - so thinking about this in another way, if we can make it so that event A *causes* event B, that causality means that A is guaranteed to happen before B, which is exactly what we want.

%% So, going back to relativistic physics for a moment, this notion of causality is very much related to the speed of light - that is, for one event in one part of a universe to be the cause of an event in a some far distant part of the universe, the effect can happen no sooner than the time it takes to send a "message" at the speed of light from the location of the cause to the location of that effect - so, let's take a cue from the universe and use the same mechanism to introduce causality in our programs - that is, let's send a message from one actor to another at the speed of light (or as close we can get on our particular hardware) - when that message from actor A reaches actor B, actor B *knows* that event A has already happened, and it can proceed with executing event B, knowing that our constraint of A happening before B has been fulfilled - moreover, conceptually, this is as soon as actor B could possibly know this - so we're not wasting any time here.

%% So, just by using actors and passing messages between them we get this basic kind of causality "for free" - we just have to remember to use message passing to denote causality wherever the order of events is important to us.

----

## Pony Paradigms
### Causality

Forked message passing causality

<code>
```ruby
<-- A1***A2 ----------------->
.    \    \                  .
<---- LA - \ ----- LB ------->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

%% The simple causality of message passing isn't always nice enough to make our programs behave in a easy-to-reason-about way, though - in fact, it still leaves us open to a whole class of application-level race conditions.

%% Consider the simple example of two actors, A and B, and a third actor L, which happens to handle logging the results of the work of A and B - so, A will send a message to L to log its results, then send a message to B to signal it to do its own work - similarly, B logs its own results to the logger - intuitively, we'd expect actor L to log the results of A, then at some time later log the results of B, as shown in this diagram.

----

## Pony Paradigms
### Causality

Forked message passing causality, breaks down

<code>
```ruby
<-- A1***A2 ----------------->
.    ^~~~~\~~~~~~~~~~~~~~,   .
<--------- \ ----- LB -- LA ->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

%% However, under simple message passing causality, this is not guaranteed - what if for some reason, actor A's message to actor L took a *really long time* to arrive, as shown by the squiggly line in *this* diagram?  It might arrive *after* actor *B's* message to actor L, so that actor L would log the results of B *before* logging the results of A, which totally goes against our intuitive understanding of time, since we know that A was guaranteed to happen before B.

----

## Pony Paradigms
### Causality

Single chain of message passing, but weird code

<code>
```ruby
<------- A2 ---------------->
.         \                 .
<-------- LA --- LB -------->
.          \     /          .
<--------- B1***B2 --------->
```
</code>

%% In order to fix this problem using simple message passing causality, we'd have to do something like make sure that our message from A to L would cause a message from L to B, then B would send a message back to L - this gets us the order we want, but it makes for a pretty weird program - I do some work, send a message to my logger, then my logger tells some other actor to do some work - we've achieved an intuitive order of events, but our code is no longer organized in an intuitive way - it's not a great solution.

----

## Pony Paradigms
### Causality

Forked message passing causality, enforced in Pony

<code>
```ruby
<-- A1***A2 ----------------->
.    \    \                  .
<---- LA - \ ----- LB ------->
.           \     /          .
<---------- B1***B2 --------->
```
</code>

%% However, it turns out that we don't need to go to such lengths because the Pony runtime can also guarantee *this* type of causality - so we write our code in the intuitive way, assuming that the Pony runtime will take care of scheduling events in such a way that causality will hold, even in this forked case.

%% This isn't just a nice feature that the creators of Pony decided to include to make Pony programmers' lives easier - this type of causal message ordering is actually critical to the way the Pony garbage collector works - Pony has a per-actor garbage collector that uses message passing to track references across actor boundaries - and the garbage collector protocol hinges on the causality of message order - if you're interested in reading more about how the garbage collector works, as I mentioned before, there's an academic paper about it you can find on the Pony web site.

----

## Pony Paradigms
### Capability Security

Unforgeable tokens of authority

%% There's one more Pony paradigm that I wanted to mention before we move on to showing some concrete code, and that's capability security - this is actually a whole field of security theory, so if you're interested I encourage you to do some research of your own because I'm not going to do it justice in a single slide - basically, what it boils down to is the idea of granting permission to do an action by passing a concrete, unforgeable token of authority.

Authority is inherently decentralized

%% This method of conveying authority is inherently decentralized, unlike more traditional permissioning systems like access control lists, which keep a list of authorized users in a central location - instead, the token itself holds all of the authority needed to perform the action, and that token can be passed or shared between users in any way they see fit according to their own level of trust.

%% This closely mirrors many real world situations where we want to delegate authority - for example, I don't need to ask permission from my car or tweak any car settings if I want to my friend access to drive it every now and then - I just need to give my friend a copy of the key - the car doesn't care who wields the key, but it's up to me to determine who I trust to share my key with.

Principle of least privilege

%% To describe another car example, let's say I want my son to go bring in the rest of the groceries from the car while I start making dinner - I don't necessarily want to grant him the authority to drive the car, so maybe I give him the key that only opens the car door, but withold the key that starts the engine - if my mischevious son is somehow able to make a copy of the key (I don't know, let's say the neighbor kid's dad is a locksmith, and my son runs over their quickly and makes a copy key for both him and his buddy), then he (and the neighbor kid) now have the capability to open my car doors whenever they want, but at least they can't take the car for a joy ride - this is called the principle of least privilege - I give out capability tokens with just enough authority to do the task at hand, and no more - this way, I minimize the overall risk of a trusted delegation "leaking" into an untrusted one.

Tokens are revocable

%% Minimizing the effect of leaked delegation are nice, but if things get out of hand I want the ability to revoke the tokens - going back to the son-and-the-neighbor-kid car example, when I found out what's going on, I'd probably want revoke access for my son and the neighbor kid - I can probably compel my son, and maybe even the neighbor kid to give me the extra keys back, but if I don't trust the neighbor kid, I can't be sure that he didn't make more copies and distribute them to other mischevious kids all over town - if I'm sufficiently worried about this, I may go to the trouble of changing the locks on my car doors - after doing so, all of the hypothetical keys floating around in the neighborhood become useless, and I can finally sleep with the peace of mind that I won't return to my car to find yet another whoopie-cushion on the seat - as in this example, most capability security systems provide a way to revoke capability tokens, making them useless to anyone who made a copy.

----

## Pony Paradigms
### Capability Security

Object references as capabilities

%% In Pony, we treat object references like capability tokens - holding a reference to an object gives you implicit, concrete authority to do things with that object, including accessing its fields, calling methods on it, or passing the reference to other parts of the program to delegate the authority to do some work.

Object references are unforgable

%% Because Pony is memory-safe (it doesn't allow any things like pointer math), new references to existing objects cannot be created out of "thin air" - references can only be created from other references, a process that models the delegation of authority.

Object references can be attenuated

%% Pony provides some patterns to attenuate object references to allow less or deny more than the original reference - there are several ways in which this can be done, and the exact mechanics are a bit outside the scope of this talk, but suffice to say that if I have an object reference that I can use to do X, Y, and Z, I have ways to pass an object reference to someone else that they can only use to do X and Y, but not Z - the ability to attenuate is crucial both to following the principle of least privilege, and in some cases, to withold the ability to revoke authority.

---

## Pony Concepts

----

## Pony Concepts
### Basic syntax

```pony
class Person
  var name: String = "John Doe"
  var age:  U8     = 0
 
  fun greeting(): String =>
    "Hello, " + name
 
  fun age_diff(that: Person): U8 =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

%% Here we have a class, with all of the typical basic features you'd expect of an object-oriented language - our class has some fields (`name` and `age`), as well as some methods (`greeting` and `age_diff`).

%% You'll note that each field has an explicit type - `name` is always a `String`, and `age` is always a `U8`, which is short for "unsigned 8-bit integer".

%% Each method also has a return type - `greeting` returns a `String` and `age_diff` returns a `U8` - like in some other languages, the final expression of the method is implicitly used as the return value - and also note that branching expressions, like the `if`/`then`/`else` block in `age_diff`, also have a value - it's whatever the value of the final expression in the executed branch is - sometimes methods have no return value, and those can be said to return type `None`, which will be added implicitly to the end of the function if you don't given an explicit return value and return type.

%% You'll see that the `age_diff` method also accepts an argument called `that`, which is of the `Person` type - because the keyword `this` is used to refer to the current receiver, just like in C++, `that` is a common Pony idiom for referring to another object of the same type.

----

## Pony Concepts
### References

```pony
let a = Person // create a new Person and refer to it as a
let b = Person // create another Person and refer to it as b
var c = Person // a, b, and c refer to three unique Persons
c = a          // c is now an alias of a
b = a          // COMPILER ERROR - can't reassign a let reference
```

%% Next, lets look at how references work.

%% Here, we create three references, two `let` references and one `var` reference - each referencing a unique new Person object - we can just say `Person` here, because referring to a type where a value is expected will implicitly call `Person.create()`, which is the name of the default constructor.

%% On the fourth line, we can reassign the `var` reference named `c` to be an alias of `a` - we essentially throw away that third `Person` object, and not both `a` and `c` refer to the same `Person`.

%% We *cannot*, however, on the fifth line, reassign the `let` reference named `b` - a `let` can only be assigned once. This should be a familiar concept to Javascript folks.

----

## Pony Concepts
### Introducing Reference Capabilities

| Safe Concurrency Pattern | Ref. Cap. |
|--------------------------|-----------|
| Share Nothing            | `tag`     |
| Share Immutable State    | `val`     |
| Transfer Isolated State  | `iso`     |

%% Now that we've seen the basic Pony syntax for some familiar concepts, let's look at how Pony's novel way of representing the concurrency concepts we've been discussing.

%% Pony uses a short keyword called a *reference capability* to represent each of these concepts.

%% Reference capabilities denote various restrictions in how object references may be used. There's the "Share Nothing" pattern, represented as `tag`, the "Share Immutable State" pattern, represented as `val`, and the "Transfer Isolated State" pattern, represented as `iso`.

----

## Pony Concepts
### Reference Capabilities Table

| Ref. Cap. | Hint       | This reference | Other references | Sendable? |
|-----------|------------|----------------|------------------|-----------|
|`ref`      | Mutable    | read/write     | read/write       | no        |
|`val`      | Immutable  | read           | read             | yes       |
|`box`      | Read-only  | read           | read/write       | no        |
|`iso`      | R/W-unique | read/write     | no access        | yes       |
|`trn`      | W-unique   | read/write     | read             | no        |
|`tag`      | Opaque     | no access      | no access        | yes       |

%% Now let's look at the full table of Pony reference capabilities - there's six in all.

%% Each object reference in Pony is marked by a specific reference capability - one of these six keywords, which dictates what can and cannot be done with that object reference - specifically, as marked in the third, fourth, and fifth columns:

%% whether or not *this* reference can read or write the object's data,
%% whether *other* references can read or write the object's data,
%% and whether the reference can be sent in a message to another actor (sendable).

%% A reference capability can only be sendable to another actor if doing so is guaranteed not to allow any data races. This guarantee is the direct result of whether the other constraints are enough to enforce one of the three safe concurrency patterns.

%% So let's take a quick look at each reference capability and what it means.

%% `ref` is a mutable reference - another way to look at it is that has no access constraints at all.  For this reason, it is not safely sendable.

%% `val` is an immutable reference - it is read-only, *and* it is guaranteed that *no other references exist* that can write to the same object - it's only readable to *you*, and it's only readable to everyone else - thus, it is guaranteed to never change.  This makes it sendable, as it is safe to share concurrently.

%% `box` is a read-only reference - however, it is not immutable because there *may* be *other references* that can write to the object -  so even though *you* can't change the object with this reference, it's possible it could be changed using another reference somewhere else - or it could just so happen that it's *actually* immutable globally, but you just have a `box`, and you don't have any way of knowing what's happening anywhere else.  This means it is not safe to share concurrently and not sendable.

%% `iso` is an isolated reference - it is read/write-unique, meaning this reference can access the object (read and write), but *no other references exist* anywhere that can access the object at all.  Because only one actor can hold an isolated reference to an object at any given time, no concurrent access is possible, so it is safe to mutate it.  It is sendable, but note that you have an actor must *give up* its isolated reference before it can be sent to another actor.  In fact, because of the uniqueness constraint, you can't alias an isolated reference at all without *downgrading* it to a *different* reference capability without the uniqueness constraint.

%% `trn` is similar to an isolated reference, but it is only write-unique instead of read/write-unique, meaning that other references to the object *can exist*, but none of them can *write* to the object.  It is *not* sendable, because it is still mutable and thus cannot be shared.  `trn` is short for *transitional*, because it is most often used as a way to temporarily mutate an object before converting it to an immutable reference.  You can convert a `trn` to a `val` by giving up the `trn` reference, which was the only one that could write to the object.  By giving up your one reference that can mutate an object, it can become immutable.

%% `tag` is an opaque reference - it allows neither reading from nor writing any of the underlying object's fields.  This may not seem very useful at first, but `tag` is actually the capability used to refer to other actors in Pony.  This makes sense, because you shouldn't be able read or write the actors field from outside the actor.  However, the `tag` reference does have the address (or *identity*) of the object, so you can still use a `tag` reference to do identity comparisons for objects, and you can still use it to send asynchronous *messages* to actors - just having the address of the actor is enough to be able to send it messages - and that's exactly what a tag reference is - an *address* without *access*.

----

## Pony Concepts
### Implicit Reference Capabilities

```pony
class Person
  var name: String = "John Doe"
  var age:  U8     = 0
 
  fun age_diff(that: Person): U8 =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

```pony
class ref Person
  var name: String val = "John Doe"
  var age:  U8 val     = 0
 
  fun box age_diff(that: Person ref): U8 val =>
    if age > that.age
    then age - that.age
    else that.age - age
    end
```

%% Let's take a look at where we use reference capabilities.

%% Here is our earlier example class - notice that we didn't use any reference capabilities in our first rendering of it - that's because we were just using the implicit defaults everywhere.

%% Every type has a default reference capability. If you don't specify a reference capability when you declare a reference, it will use the default capability for that type. The `String` and `U8` types happen to be `val` by default, meaning that they're immutable values.  Note that this doesn't mean you can't assign a different value to the `name` field of a `Person` - it just means that the `String` object itself cannot be changed.

%% The `Person` type has a default reference capability of `ref`, indicating a "normal" mutable reference with no particular restrictions. If you wanted to use a different capability, like `iso`, so that it would be sendable, you would have to specify `Person iso` instead of just `Person`.

%% We also see the `box` reference capability in the definition of the `age_diff` method - this doesn't refer to the arguments or return value, but rather to the `Person` object instance that we're operating on - again, in Pony we refer to the current instance as `this` - when you declare a method but don't specify a reference capability for it, `box` is the assumed default.

%% Remember that the `box` reference capability means that we can only read from it, not write to it - because our view of the `Person` instance is a `box`, this means that we can't change any fields of the `Person` from within the `age_diff` method - this makes sense, because just measuring a `Person` object shouldn't change it - if we wanted to change state from within the method, we'd have to declare it as `fun ref age_diff` instead.

%% When the compiler knows that the `age_diff` method doesn't modify any state, it can make certain performance optimizations based on that guarantee.

%% An astute viewer might notice that we're also not modifying the *other* `Person` in the `age_diff` method either, so we can actually change that parameter signature to accept a `Person box` instead of a `Person ref`.

%% From another perspective, declaring as `fun box age_diff` means that we can call this method on any `Person` that we have read access to, not caring whether we have write access or whether anyone else has read or write access.

%% If we were to declare it as `fun ref age_diff`, we would be prevented from calling that method if we didn't have write access to the `Person`.

%% If we were to declare it as `fun val age_diff`, we would be prevented from calling that method if *anyone else* had write access to the `Person`.

%% If we were to declare it as `fun iso age_diff`, we would be prevented from calling that method if anyone else had *any access* to the `Person`, read *or* write access.

%% Note that in general, restricting what we can do within the method gives us more freedom in how we can call, and vice versa - this is a common theme with compilers - imposing restrictions actually give you more freedom in other ways.

%% Reference capabilities are all about carefully choosing the restrictions we want so that we have freedom (and concurrency) where it counts.

----

## Pony Concepts
### Reference Capabilities Summary

There's more to see, but not today `*`*wink*`*`

%% There's so much more to talk about with the details of how reference capabilities work - the rules for *downgrading* to lower capabilities or *lifting* to higher capabilities - the rules for how capabilities to objects "filter" (or *combine with*) the capabilities of those objects' fields - but I think I've already talked enough for today, so I'll leave the rest of the discovery to those of you who are interested enough to read about it or ask me specific questions.

There's a learning curve, but it's worth it!

%% Reference capabilities may seem convoluted, but if you spend a little time using them, they become second-nature, and you start to see all of your concurrency problems in these terms.

Ref caps bring explicit structure to lockless concurrency

%% These concepts are implicit in our code anyway when we're writing concurrent applications. Making the ideas explicit in syntax helps us organize our thoughts and prove to ourselves and the compiler that what we're doing is safe.

Ref caps have no runtime cost!

%% One of the really powerful benefits of how reference capabilities are implemented in Pony is that they have no runtime cost - there are no safety checks executed in your running application, because it's all proven safe at compile-time - in fact, reference capabilities don't exist at all at runtime - they are compile-time constraints that fall away in the final compiled code.

%% The other runtime cost you avoid is the cost of synchronization - again, Pony is lockless - so every time your code is accessing data, it doesn't ever have to wait to acquire a lock - the access is already proven to be safe. This means you only spending those precious CPU cycles doing the real work of the application.

---

# Questions?

---

![LFNW-finish](http://i.imgur.com/9eAtxdp.png)
