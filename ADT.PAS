unit ADT;


INTERFACE

uses keys,strings;


type  basisOPtr                 = ^basisO;
      basisO                    = object
        constructor  init;
        destructor   done; virtual;
      end;

      stringNodeOPtr            = ^stringNodeO;
      stringNodeO               = object(basisO)
        keyValue                  : stringPtr;
        left                      : stringNodeOPtr;
        right                     : stringNodeOPtr;
        constructor  init(aString : string);
        destructor   done; virtual;
        procedure    setKey(aString : string);
        procedure    getData; virtual;
        function     key        : string;
        function     vKey       : string; virtual;
        function     leftChild  : stringNodeOPtr;
        function     rightChild : stringNodeOPtr;
      end;

      stringTreeOPtr             = ^stringTreeO;
      stringTreeO                = object
        head                       : stringNodeOPtr;
        constructor  init;
        destructor   done;
        procedure    addNode(aNode : stringNodeOPtr);
        procedure    dump; virtual;
        procedure    disposeTree;
        function     iterate                    : string; virtual;
        function     member(candidate : string) : boolean;
      end;

      doubleNodeOPtr            = ^doubleNodeO;
      doubleNodeO               = object(basisO)
        previous                  : doubleNodeOPtr;
        next                      : doubleNodeOPtr;
        constructor  init;
        destructor   done; virtual;
        function     getData      : basisOPtr; virtual;
        function     getString    : string; virtual;
        function     mayBeDeleted : boolean; virtual;
      end;

      doubleListOPtr            = ^doubleListO;
      doubleListO               = object
        firstPtr                  : doubleNodeOPtr;
        lastPtr                   : doubleNodeOPtr;
        positionPtr               : doubleNodeOPtr;
        remPos                    : doubleNodeOPtr;
        constructor  init;
        destructor   done; virtual;
        function     first                         : doubleNodeOPtr;
        function     last                          : doubleNodeOPtr;
        function     position                      : doubleNodeOPtr;
        function     previous                      : doubleNodeOPtr;
        function     next                          : doubleNodeOPtr;
        function     iterate                       : doubleNodeOPtr;
        function     member(aPtr : doubleNodeOPtr) : boolean; virtual;
        function     isEmpty                       : boolean;
        function     startOfList                   : boolean;
        function     endOfList                     : boolean;
        function     getData                       : basisOPtr; virtual;
        function     getString                     : string; virtual;
        function     mayBeDeleted                  : boolean; virtual;
        function     numberOfElements              : byte;
        procedure    emptyList; virtual;
        procedure    goForwards;
        procedure    goBackwards;
        procedure    goToStart;
        procedure    goToEnd;
        procedure    goToPosition(where : doubleNodeOPtr);
        procedure    rememberPosition;
        procedure    restorePosition;
        procedure    addElement(aPtr : doubleNodeOPtr); virtual;
        procedure    addElementAt(aPos : word; aPtr : doubleNodeOPtr); virtual;
        procedure    removeElement(where : doubleNodeOPtr); virtual;
        procedure    dump; virtual;
      end;

      generalTreeNodeOPtr       = ^generalTreeNodeO;

      generalTreeListNodeOPtr   = ^generalTreeListNodeO;
      generalTreeListNodeO      = object(doubleNodeO)
        subtreeValue              : generalTreeNodeOPtr;
        constructor  init(aGeneralTreeNode : generalTreeNodeOPtr);
        destructor   done; virtual;
        function     subtree : generalTreeNodeOPtr;
      end;

      generalTreeListOPtr       = ^generalTreeListO;
      generalTreeListO          = object(doubleListO)
        constructor  init;
        destructor   done; virtual;
        function     getFirst    : generalTreeNodeOPtr;
        function     getLast     : generalTreeNodeOPtr;
        function     getThis     : generalTreeNodeOPtr;
        function     getPrevious : generalTreeNodeOPtr;
        function     getNext     : generalTreeNodeOPtr;
      end;

      generalTreeNodeO          = object
        parentValue               : generalTreeNodeOPtr;
        listOfChildrenValue       : generalTreeListOPtr;
        depthValue                : word;
        constructor  init(theParent : generalTreeNodeOPtr);
        destructor   done; virtual;
        function     parent             : generalTreeNodeOPtr;
        function     listOfChildren     : generalTreeListOPtr;
        function     depth              : word;
        function     hasParent          : boolean;
        function     hasChildren        : boolean;
        function     numberOfChildren   : byte; virtual;
        function     firstChild         : generalTreeNodeOPtr;
        function     lastChild          : generalTreeNodeOPtr;
        function     thisChild          : generalTreeNodeOPtr;
        function     previousChild      : generalTreeNodeOPtr;
        function     nextChild          : generalTreeNodeOptr;
        function     childNo(no : byte) : generalTreeNodeOPtr;
        function     moreChildren       : boolean;
        function     siblingNumber      : byte; virtual;
        function     numberOfSiblingsOnThisLevel : byte; virtual;
        procedure    setDepth(value : word);
        procedure    addChild(aChild : generalTreeNodeOPtr);
        procedure    addChildAt(aPos : byte; aChild : generalTreeNodeOPtr);
        procedure    setThisChild(aNumber : byte);
      end;

      generalTreeOPtr           = ^generalTreeO;
      generalTreeO              = object
        rootValue                 : generalTreeNodeOPtr;
        currentSubtreeValue       : generalTreeNodeOPtr;
        storedTree                : generalTreeNodeOPtr;
        constructor  init(rootNode : generalTreeNodeOPtr);
        destructor   done; virtual;
        function     root                          : generalTreeNodeOptr;
        function     currentSubtree                : generalTreeNodeOPtr;
        function     depth                         : word;
        function     numberOfNodes                 : word;
        procedure    setCurrentSubtree(aTree : generalTreeNodeOPtr);
        procedure    addChild(aChild : generalTreeNodeOPtr); virtual;
        procedure    goToRoot;
        procedure    goToParent;
        procedure    goToNextNodeOnTheRight;
        procedure    rememberThisChild;
        procedure    restoreThisChild;
        procedure    deleteTree;
      end;


IMPLEMENTATION


(**************************************************************************
 *                                                                        *
 *     basisO's methods                                                   *
 *                                                                        *
 **************************************************************************)


constructor basisO.init;

begin
end;


destructor basisO.done;

begin
end;


(**************************************************************************
 *                                                                        *
 *     stringNodeO(basisO)'s methods                                      *
 *                                                                        *
 **************************************************************************)


constructor stringNodeO.init(aString : string);

begin
  basisO.init;
  keyValue:=strPtr(aString);
  left:=nil;
  right:=nil
end;


destructor stringNodeO.done;

begin
  delStr(keyValue);
  basisO.done
end;


procedure stringNodeO.setKey(aString : string);

begin
  delStr(keyValue);
  keyValue:=strPtr(aString)
end;


procedure stringNodeO.getData;

begin
  writeLn(keyValue^)
end;


function stringNodeO.key : string;

begin
  key:=keyValue^
end;


function stringNodeO.vKey : string;

begin
  vKey:=keyValue^
end;


function stringNodeO.leftChild : stringNodeOPtr;

begin
  leftChild:=left
end;


function stringNodeO.rightChild : stringNodeOPtr;

begin
  rightChild:=right
end;


(**************************************************************************
 *                                                                        *
 *     stringTreeO's methods                                              *
 *                                                                        *
 **************************************************************************)


constructor stringTreeO.init;

begin
  head:=nil
end;


destructor stringTreeO.done;

begin
  disposeTree
end;


procedure stringTreeO.addNode(aNode : stringNodeOPtr);


  procedure traverse(var aPtr : stringNodeOPtr);

  begin
    if (aPtr<>nil) then
      if aNode^.vKey<=aPtr^.vKey then
        traverse(aPtr^.left)
      else
        traverse(aPtr^.right)
    else
      aPtr:=aNode
   end;


begin
  if (head<>nil) then
    traverse(head)
  else
    head:=aNode
end;


procedure stringTreeO.dump;


  procedure traverse(aPtr : stringNodeOPtr);

  begin
    if aPtr<>nil then
      begin
        traverse(aPtr^.left);
        writeLn(aPtr^.vKey);
        traverse(aPtr^.right)
      end
  end;


begin
  traverse(head)
end;


procedure stringTreeO.disposeTree;


  procedure traverse(aPtr : stringNodeOPtr);

  begin
    if (aPtr<>nil) then
      begin
        traverse(aPtr^.left);
        traverse(aPtr^.right);
        dispose(aPtr,done)
      end
  end;


begin
   traverse(head);
   head:=nil
end;


function stringTreeO.iterate : string;

begin
end;


function stringTreeO.member(candidate : string) : boolean;

var   isMember                  : boolean;


  procedure traverse(aPtr : stringNodeOPtr);

  begin
    if ((aPtr<>nil) and (not isMember)) then
      if (candidate<aPtr^.key) then
        traverse(aPtr^.left)
      else if (candidate>aPtr^.key) then
        traverse(aPtr^.right)
    else
      isMember:=true
   end;


begin
  isMember:=false;
  traverse(head);
  member:=isMember
end;


(**************************************************************************
 *                                                                        *
 *     doubleNodeO's methods                                              *
 *                                                                        *
 **************************************************************************)


constructor doubleNodeO.init;

begin
  basisO.init;
  previous:=nil;
  next:=nil
end;


destructor doubleNodeO.done;

begin
  basisO.done
end;


function doubleNodeO.getData : basisOPtr;

begin
  getData:=nil
end;


function doubleNodeO.getString : string;

begin
  getString:=''
end;


function doubleNodeO.mayBeDeleted : boolean;

begin
   mayBeDeleted:=true
end;



(**************************************************************************
 *                                                                        *
 *     doubleListO's methods                                              *
 *                                                                        *
 **************************************************************************)


constructor doubleListO.init;

begin
  firstPtr:=nil;
  lastPtr:=firstPtr;
  positionPtr:=firstPtr;
  remPos:=nil
end;


destructor doubleListO.done;

begin
  emptyList
end;


function doubleListO.first : doubleNodeOPtr;

begin
  first:=firstPtr
end;


function doubleListO.last : doubleNodeOPtr;

begin
  last:=lastPtr
end;


function doubleListO.position : doubleNodeOPtr;

begin
  position:=positionPtr
end;


function doubleListO.previous : doubleNodeOPtr;

begin
  previous:=positionPtr^.previous
end;


function doubleListO.next : doubleNodeOPtr;

begin
  next:=positionPtr^.next
end;


function doubleListO.iterate : doubleNodeOPtr;

begin
  iterate:=positionPtr;
  if (not endOfList) then
    positionPtr:=positionPtr^.next
  else
    goToStart
end;


function doubleListO.member(aPtr : doubleNodeOPtr) : boolean;

begin
  member:=false
end;


function doubleListO.isEmpty : boolean;

begin
  isEmpty:=(firstPtr=nil)
end;


function doubleListO.startOfList : boolean;

begin
  startOfList:=(positionPtr=firstPtr)
end;


function doubleListO.endOfList : boolean;

begin
  endOfList:=(positionPtr=lastPtr)
end;


function doubleListO.numberOfElements : byte;

var   count                     : word;

begin
  rememberPosition;
  if (not isEmpty) then
    begin
      goToStart;
      count:=1;
      while (not endOfList) do
        begin
          goForwards;
          inc(count)
        end;
      numberOfElements:=count
    end
  else
    numberOfElements:=0;
  restorePosition
end;


procedure doubleListO.emptyList;

begin
  if (not isEmpty) then
    begin
      goToEnd;
      while (not startOfList) do
        begin
          goBackwards;
          dispose(positionPtr^.next,done)
        end;
      dispose(positionPtr,done)
    end;
  firstPtr:=nil;
  lastPtr:=nil;
  positionPtr:=nil
end;


procedure doubleListO.goForwards;

begin
  if (positionPtr<>lastPtr) then
    positionPtr:=positionPtr^.next
end;


procedure doubleListO.goBackwards;

begin
  if (positionPtr<>firstPtr) then
    positionPtr:=positionPtr^.previous
end;


procedure doubleListO.goToStart;

begin
  positionPtr:=firstPtr
end;


procedure doubleListO.goToEnd;

begin
  positionPtr:=lastPtr
end;


procedure doubleListO.goToPosition(where : doubleNodeOPtr);

begin
  positionPtr:=where
end;


procedure doubleListO.rememberPosition;

begin
  remPos:=position
end;


procedure doubleListO.restorePosition;

begin
  positionPtr:=remPos;
  remPos:=nil
end;


procedure doubleListO.addElement(aPtr : doubleNodeOPtr);

begin
  if (not isEmpty) then
    begin
      aPtr^.previous:=lastPtr;
      aPtr^.next:=nil;
      lastPtr^.next:=aPtr;
      lastPtr:=aPtr
    end
  else
    begin
      firstPtr:=aPtr;
      lastPtr:=aPtr;
      positionPtr:=aPtr
    end
end;


procedure doubleListO.addElementAt(aPos : word; aPtr : doubleNodeOPtr);

var   i                         : word;
      max                       : word;

begin
  max:=numberOfElements;
  if (aPos<max) then
    begin
      goToStart;
      for i:=1 to aPos-1 do
        goForwards;
      aPtr^.next:=position^.next;
      aPtr^.previous:=position;
      position^.next^.previous:=aPtr;
      position^.next:=aPtr
    end
  else if (aPos=max) then
    addElement(aPtr)
end;


procedure doubleListO.removeElement(where : doubleNodeOPtr);


  procedure doRemove(where : doubleNodeOPtr);

  begin
    if ((where=first) and (where=last)) then
      begin
        dispose(where,done);
        firstPtr:=nil;
        lastPtr:=nil
      end
    else if (where=first) then
      begin
        firstPtr:=first^.next;
        first^.previous:=nil;
        dispose(where,done)
      end
    else if (where=last) then
      begin
        lastPtr:=last^.previous;
        last^.next:=nil;
        dispose(where,done)
      end
    else
      begin
        where^.previous^.next:=where^.next;
        where^.next^.previous:=where^.previous;
        dispose(where,done)
      end
  end;


begin
  if ((where=position) and (where<>last)) then
    goForwards
  else if ((where=position) and (where<>first)) then
    goBackwards
  else if (where=position) then
    positionPtr:=nil;
  doRemove(where)
end;


function doubleListO.mayBeDeleted : boolean;

begin
  mayBeDeleted:=true
end;


function doubleListO.getData : basisOPtr;

begin
  if (positionPtr<>nil) then
    getData:=positionPtr^.getData
  else
    getData:=nil
end;


function doubleListO.getString : string;

begin
  getString:=positionPtr^.getString
end;


procedure doubleListO.dump;

var   aPtr                      : basisOPtr;

begin
  goToStart;
  aPtr:=getData;
  while (not endOfList) do
    begin
      goForwards;
      aPtr:=getData
    end
end;


(**************************************************************************
 *                                                                        *
 *     generalTreeListNodeO(doubleNodeO)'s methods                        *
 *                                                                        *
 **************************************************************************)


constructor generalTreeListNodeO.init(aGeneralTreeNode : generalTreeNodeOPtr);

begin
  doubleNodeO.init;
  subtreeValue:=aGeneralTreeNode
end;


destructor generalTreeListNodeO.done;

begin
  dispose(subtreeValue,done);
  doubleNodeO.done
end;


function generalTreeListNodeO.subtree : generalTreeNodeOPtr;

begin
  subtree:=subtreeValue
end;


(**************************************************************************
 *                                                                        *
 *     generalTreeListO(doubleNodeO)'s methods                            *
 *                                                                        *
 **************************************************************************)


constructor generalTreeListO.init;

begin
  doubleListO.init
end;


destructor generalTreeListO.done;

begin
  doubleListO.done
end;


function generalTreeListO.getFirst : generalTreeNodeOPtr;

begin
  getFirst:=generalTreeListNodeOPtr(first)^.subtree
end;


function generalTreeListO.getLast : generalTreeNodeOPtr;

begin
  getLast:=generalTreeListNodeOPtr(last)^.subtree
end;


function generalTreeListO.getThis : generalTreeNodeOPtr;

begin
  getThis:=generalTreeListNodeOPtr(position)^.subtree
end;


function generalTreeListO.getPrevious : generalTreeNodeOPtr;

begin
  getPrevious:=generalTreeListNodeOPtr(previous)^.subtree
end;


function generalTreeListO.getNext  : generalTreeNodeOPtr;

begin
  getNext:=generalTreeListNodeOPtr(next)^.subtree
end;


(**************************************************************************
 *                                                                        *
 *     generalTreeNodeO's methods                                         *
 *                                                                        *
 **************************************************************************)


constructor generalTreeNodeO.init(theParent : generalTreeNodeOPtr);

begin
  parentValue:=theParent;
  new(listOfChildrenValue,init);
  if (theParent<>nil) then
    setDepth(succ(theParent^.depth))
  else
    setDepth(0)
end;


destructor generalTreeNodeO.done;

begin
  dispose(listOfChildrenValue,done)
end;


function generalTreeNodeO.parent : generalTreeNodeOPtr;

begin
  parent:=parentValue
end;


function generalTreeNodeO.listOfChildren : generalTreeListOPtr;

begin
  listOfChildren:=listOfChildrenValue
end;


function generalTreeNodeO.depth : word;

begin
  depth:=depthValue
end;


function generalTreeNodeO.hasParent : boolean;

begin
  hasParent:=(parent<>nil)
end;


function generalTreeNodeO.hasChildren : boolean;

begin
  hasChildren:=(listOfChildren^.position<>nil)
end;


function generalTreeNodeO.numberOfChildren : byte;

var   count                     : byte;

begin
  if hasChildren then
    with listOfChildren^ do
      begin
        count:=1;
        rememberPosition;
        goToStart;
        while (not endOfList) do
          begin
            goForwards;
            inc(count)
          end;
        restorePosition;
        numberOfChildren:=count
      end
  else
    numberOfChildren:=0
end;


function generalTreeNodeO.firstChild : generalTreeNodeOPtr;

begin
  if hasChildren then
    firstChild:=listOfChildren^.getFirst
  else
    firstChild:=nil
end;


function generalTreeNodeO.lastChild : generalTreeNodeOPtr;

begin
  if hasChildren then
    lastChild:=listOfChildren^.getLast
  else
    lastChild:=nil
end;


function generalTreeNodeO.thisChild : generalTreeNodeOPtr;

begin
  if hasChildren then
    thisChild:=listOfChildren^.getThis
  else
    thisChild:=nil
end;


function generalTreeNodeO.previousChild : generalTreeNodeOPtr;

begin
  if hasChildren then
    previousChild:=listOfChildren^.getPrevious
  else
    previousChild:=nil
end;


function generalTreeNodeO.nextChild : generalTreeNodeOptr;

begin
  if hasChildren then
    nextChild:=listOfChildren^.getNext
  else
    nextChild:=nil
end;


function generalTreeNodeO.childNo(no : byte) : generalTreeNodeOPtr;

var   i                         : byte;

begin
  if (hasChildren and (no<=numberOfChildren)) then
    with listOfChildren^ do
      begin
        goToStart;
        for i:=1 to no-1 do
          goForwards;
        childNo:=thisChild
      end
  else
    childNo:=nil
end;


function generalTreeNodeO.moreChildren : boolean;

begin
  moreChildren:=(not listOfChildren^.endOfList)
end;


function generalTreeNodeO.siblingNumber : byte;

begin
  siblingNumber:=0
end;


function generalTreeNodeO.numberOfSiblingsOnThisLevel : byte;

begin
  numberOfSiblingsOnThisLevel:=0
end;


procedure generalTreeNodeO.setDepth(value : word);

begin
  depthValue:=value
end;


procedure generalTreeNodeO.addChild(aChild : generalTreeNodeOPtr);

begin
  listOfChildren^.addElement(new(generalTreeListNodeOPtr,init(aChild)))
end;


procedure generalTreeNodeO.addChildAt(aPos : byte;
                                    aChild : generalTreeNodeOPtr);

begin
  listOfChildren^.addElementAt(aPos,new(generalTreeListNodeOPtr,init(aChild)))
end;


procedure generalTreeNodeO.setThisChild(aNumber : byte);

var   count                     : byte;

begin
  if hasChildren then
    if (aNumber<numberOfChildren) then
      with listOfChildren^ do
        begin
          goToStart;
          for count:=1 to aNumber-1 do
            goForwards
        end
    else if (aNumber=numberOfChildren) then
      listOfChildren^.goToEnd
end;


(**************************************************************************
 *                                                                        *
 *     generalTreeO's methods                                             *
 *                                                                        *
 **************************************************************************)


constructor generalTreeO.init(rootNode : generalTreeNodeOPtr);

begin
  rootValue:=rootNode;
  setCurrentSubtree(root);
end;


destructor generalTreeO.done;

begin
  deleteTree
end;


function generalTreeO.root : generalTreeNodeOptr;

begin
  root:=rootValue
end;


function generalTreeO.currentSubtree : generalTreeNodeOPtr;

begin
  currentSubtree:=currentSubtreeValue
end;


function generalTreeO.depth : word;

begin
  depth:=currentSubtree^.depth
end;


function generalTreeO.numberOfNodes : word;

var   count                     : word;


  procedure traverse;

  var   i                         : byte;

  begin
    for i:=1 to currentSubtree^.numberOfChildren do
      begin
        setCurrentSubtree(currentSubtree^.childNo(i));
        inc(count);
        traverse;
        goToParent
      end
  end;


begin
  count:=1;
  goToRoot;
  traverse;
  numberOfNodes:=count
end;


procedure generalTreeO.setCurrentSubtree(aTree : generalTreeNodeOPtr);

begin
  currentSubtreeValue:=aTree;
  if (currentSubtree<>nil) then
    if currentSubtree^.hasParent then
      with currentSubtree^.parent^.listOfChildren^ do
        begin
          goToStart;
          while (getThis<>aTree) do
            goForwards
        end
end;


procedure generalTreeO.addChild(aChild : generalTreeNodeOPtr);

begin
  currentSubtree^.addChild(aChild)
end;


procedure generalTreeO.goToRoot;

begin
  setCurrentSubtree(root)
end;


procedure generalTreeO.goToParent;

begin
  if (currentSubtree^.hasParent) then
    setCurrentSubtree(currentSubtree^.parent)
end;


procedure generalTreeO.goToNextNodeOnTheRight;

var   storedNode                : generalTreeNodeOPtr;


  function traverseUpwards : boolean;

  begin
    with currentSubtree^ do
      if (hasParent and parent^.moreChildren) then
        begin
          setCurrentSubtree(parent^.nextChild);
          traverseUpwards:=true
        end
      else
        if hasParent then
          begin
            goToParent;
            traverseUpwards:=traverseUpwards
          end
        else
          traverseUpwards:=false
  end;


begin
  storedNode:=currentSubtree;
  if (not traverseUpwards) then
    setCurrentSubtree(storedNode)
end;


procedure generalTreeO.rememberThisChild;

begin
  storedTree:=currentSubtree
end;


procedure generalTreeO.restoreThisChild;

begin
  setCurrentSubtree(storedTree)
end;


procedure generalTreeO.deleteTree;

begin
  setCurrentSubtree(nil);
  dispose(root,done)
end;


end.