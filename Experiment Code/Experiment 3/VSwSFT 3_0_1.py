"""
    Visual Search with SFT
    Author: Joseph J Glavan     j.glavan4@gmail.com
    2/20/2019
    
    Starting from Version 1.7.2
    Using 4x4 DFP where the target can be any stimulus type
    
    Still homogeneous distractors
    
    
"""

from __future__ import division #so that 1/3=0.333 instead of 1/3=0
from psychopy import visual, core, data, event, logging, gui
from psychopy.constants import * #things like STARTED, FINISHED
import autopy
from time import sleep
import numpy as np  # whole numpy lib is available, prepend 'np.'
from numpy import sin, cos, tan, log, log10, pi, average, sqrt, std, deg2rad, rad2deg, linspace, asarray
from numpy.random import random, randint, normal, shuffle, choice
import os #handy system and path functions
import collections # needed to convert unicode stuff



##########################################################################################################

expVersion = '3.0.1'

##########################################################################################################

NUM_BLOCKS = 1#37
NUM_TRIALS = NUM_BLOCKS*480#16
CAP_BLOCKS = 4#23
CAP_TRIALS = CAP_BLOCKS*24#4
BREAK_TRIALS = int(NUM_TRIALS/2)
NUM_DISTRACTORS = 23 # Set this from config file in the future
MIN_SEP = 100    # Minimum separation of stimuli (in pixels) USED FROM THE CENTER
FALL_RATE = 50  # Rate at which stimuli fall in dynamic condition (in pixels per second)
TOLERANCE = 100  # How many pixels outside the target's rect a response can fall and still be counted correct
MAX_TIME = 20   # Maximum duration of a trial (in seconds)
DISPLAY_DIMENSIONS = [1280,1024] #psychopy.display.list_modes()[0]
READY_TIME = 1  # How long to display the "Get Ready..." message before beginning a trial
STIM_RAD = 20 # Radius of stimuli
_COLOR1 = (255,0,0)
_COLOR2 = (248,12,94)
_COLOR3 = (237,28,152)
_COLOR4 = (217,43,208)


#store info about the experiment session
expName='VSwSFT_SR2'    # Name of the Experiment
expInfo={'participant':'TEST', 'session':'1', 'condition (s/d)':'s', 'response style (s/d)':'s'}  # condition: s = static stimuli, d = dynamic stimuli; response style: s = click when found, d = click on target
dlg=gui.DlgFromDict(dictionary=expInfo,title=expName)
if dlg.OK==False: core.quit() #user pressed cancel
expInfo['condition'] = expInfo.pop('condition (s/d)').lower()
expInfo['response style'] = expInfo.pop('response style (s/d)').lower()
if ((expInfo['condition'] != 's' and expInfo['condition'] != 'd') or (expInfo['response style'] != 's' and expInfo['response style'] != 'd')): core.quit() # cannot run experiment without a specified condition and response style
expInfo['date']=data.getDateStr()#add a simple timestamp
expInfo['expName']=expName

#if expInfo['session'] == '1':
#    NUM_BLOCKS = 22
#    NUM_TRIALS = NUM_BLOCKS*16

#setup files for saving
if not os.path.isdir('data'):
    os.makedirs('data') #if this fails (e.g. permissions) we will get error
bhead = 'data' + os.path.sep + 'behavioral'
shead = 'data' + os.path.sep + 'stimuli'
if not os.path.isdir(bhead):
    os.makedirs(bhead) #if this fails (e.g. permissions) we will get error
if not os.path.isdir(shead):
    os.makedirs(shead) #if this fails (e.g. permissions) we will get error
filename = bhead + os.path.sep + '%s_%s' %(expInfo['participant'], expInfo['date'])
sfilename = shead + os.path.sep + '%s_%s' %(expInfo['participant'], expInfo['date'])
file = filename+'.txt'
sfile = sfilename+'_stimuli.txt'
logFile=open(file, 'a')
stimFile=open(sfile, 'a')

#an ExperimentHandler isn't essential but helps with data saving
thisExp = data.ExperimentHandler(name=expName, version=expVersion,
    extraInfo=expInfo, runtimeInfo=None,
    originPath=None,
    savePickle=False, saveWideText=False,
    dataFileName=filename)

# Setup the Window
win = visual.Window(size=DISPLAY_DIMENSIONS, fullscr=True, screen=0, allowGUI=False, allowStencil=False,
    monitor='Sony', color=[1,1,1], colorSpace='rgb', units="pix")

# Initialise components for Experiment
instructionsClock=core.Clock()
trialClock=core.Clock()
sInstructions = visual.TextStim(win=win, ori=0, name='SRinstructions',
    text='After the words "Get Ready..." are displayed, you will see a field of red, pink, and purple colored circles, octagons, and diamonds.\n\nFind the RED CIRCLE as quickly as you can.\n\nAfter you find the RED CIRCLE, click the LEFT mouse button.\nIf there is NO red circle, click the RIGHT mouse button.\n\nIf you responded that there was a red circle, you will be asked to click with the LEFT mouse button on where you found the red circle.\nIf you responded that there was no red circle, the trial will progress normally.\n\n\nClick the mouse when you are ready to begin...',
    font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
dInstructions = visual.TextStim(win=win, ori=0, name='DRinstructions',
    text='After the words "Get Ready..." are displayed, you will see a field of red, pink, and purple colored circles, octagons, and diamonds.\n\nFind the RED CIRCLE as quickly as you can.\n\nAfter you find the RED CIRCLE, click on it with the LEFT mouse button.\n\nIf there is NO red circle, click the RIGHT mouse button anywhere.\n\n\nClick the mouse when you are ready to begin...',
    font='Arial', pos=[0, 0], units="pix",height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
readyCue = visual.TextStim(win=win, ori=0, name='ready cue',
    text='Get Ready...', units="norm",
    font='Arial', pos=[0, 0], height=0.1,wrapWidth=None,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
forceBreak = visual.TextStim(win=win, ori=0, name='break start',
    text='You may now take a one minute break.', units="pix",
    font='Arial', pos=[0, 0], height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
forceResume = visual.TextStim(win=win, ori=0, name='break end',
    text='Click the mouse whenever you are ready to resume the experiment...', units="pix",
    font='Arial', pos=[0, 0], height=40, wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
outcome_message = visual.TextStim(win=win, ori=0, name='Outcome_message',
    text='You have finished the experiment. Please go see the experimenter at this time.\n\nThank you for your participation!\n\n\n',
    font='Arial', pos=[0, 0], height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100, units="pix",
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
fourTrialWarning = visual.TextStim(win=win, ori=0, name='fourTrialWarning',
    text='You will first receive four practice trials to familarize yourself with the colors and shapes.\n\nFeedback will be provided after each trial. You may take as long as you wish to study any mistakes.\n\n(Left) clicking the mouse will advance to the next trial.',
    font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
sixteenTrialWarning = visual.TextStim(win=win, ori=0, name='fourTrialWarning',
    text='You will first receive sixteen practice trials to familarize yourself with the colors and shapes.\n\nFeedback will be provided after each trial. You may take as long as you wish to study any mistakes.\n\n(Left) clicking the mouse will advance to the next trial.',
    font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)
endOfPracticeWarning = visual.TextStim(win=win, ori=0, name='fourTrialWarning',
    text='You have finished the practice trials for this block. The real trials will now begin.\n\nFeedback will NOT be provided after each trial.\n\nTrials will advance automatically after you have made your response.\n\n(Left) click the mouse when you are ready to continue.',
    font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
    color='black', colorSpace='rgb', opacity=1, depth=0.0)

mouse = event.Mouse(visible=False, win=win)
#mouse = event.Mouse(visible=False, newPos=[0,0], win=win)
logFile.write("Version\tDate\tStimuli\tMethod\tSubject\tSession\tCondition\tTrial\tTarget\tTColor\tTShape\tDColor\tDShape\tDistractors\tChannel1\tChannel2\tLMouseButton\tRMouseButton\tRT\tTargetX\tTargetY\tResponseX\tResponseY\tCorrect\n") # DO WE WANT TO RECORD DISTRACTOR LOCATIONS? WHAT ABOUT STIMULI LOCATIONS DURING MOVEMENT?
stimHead = "Date\tSubject\tSession\tCondition\tDistractors\tTrial\tTime\tTargetX\tTargetY\t"
for i in range(NUM_DISTRACTORS):
    stimHead = stimHead + "D" + str(i+1) + "X\tD" + str(i+1) + "Y\t"
stimHead = stimHead.rstrip('\t') + "\n"
stimFile.write(stimHead)

# Create some handy timers
globalClock=core.Clock() #to track the time since experiment started
routineTimer=core.CountdownTimer() #to track time remaining of each (non-slip) routine
readyTimer=core.CountdownTimer()

def DecodeUnicode(data):
    if isinstance(data, basestring):
        return str(data)
    elif isinstance(data, collections.Mapping):
        return dict(map(DecodeUnicode, data.iteritems()))
    elif isinstance(data, collections.Iterable):
        return type(data)(map(DecodeUnicode, data))
    else:
        return data

def NewStimuli (win, edg, rad, col, x, y, orientation=22.5):
    """Generate a new shape stimuli"""
    if edg == 4:
        orientation -= 22.5
    if edg == 6:
        orientation -= 22.5
    if edg < 3:
        return visual.Circle(win=win, radius=rad, lineColor=col, fillColor=col, ori=orientation, pos=[x,y], units='pix', lineColorSpace='rgb255', fillColorSpace='rgb255', opacity=1.0)
    else:
        return visual.Polygon(win=win, edges=edg, radius=rad, lineColor=col, fillColor=col, pos=[x,y], ori=orientation, units='pix', lineColorSpace='rgb255', fillColorSpace='rgb255', opacity=1.0)



def VisualSearch(nBlocks, conditionsFile):

    #---- Set Up Visual Search Block ----#
    block=data.TrialHandler(nReps=nBlocks, method='random', 
        extraInfo=expInfo, originPath=None,
        trialList=data.importConditions(conditionsFile),
        seed=None, name='VS block')
    thisExp.addLoop(block)#add the loop to the experiment
    trialcounter = 0

    for thisTrial in block:
        # Don't need anymore because I'm specifying color and shape by a number instead of H,L,A
        # # Hacks because the conditions aren't reading in properly and I can't figure out why ("A" was being replaced by "datetime.date(.)")
        # if thisTrial.color != 'H' and thisTrial.color != 'L':
            # block.thisTrial['color'] = u'A'
        # if thisTrial.shape != 'H' and thisTrial.shape != 'L':
            # block.thisTrial['shape'] = u'A'
        
        #------Give them a break after xxx trials ------
        if trialcounter==BREAK_TRIALS:
            forceBreak.setAutoDraw(True)
            win.flip()
            sleep(60.00)
            forceBreak.setAutoDraw(False)
            win.flip()
            forceResume.setAutoDraw(True)
            win.flip()
            while sum(mouse.getPressed()) == 0:
                pass
            event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            forceResume.setAutoDraw(False)
            win.flip()
            
        #------Prepare to start Routine"trial"-------
        trialcounter += 1
        response = [0,0]
        rt = -1
        clickLoc = [None,None]
        
        trialComponents = {'mouse':mouse, 'distractors':[]}
        #load stimuli
        thisTrial = DecodeUnicode(thisTrial) # IDK why everything is getting converted to unicode strings but this should turn them back to str
        # UNFORTUNATELY it seems that this also makes the ordered dictionary lose its attribute access ability
        if thisTrial["target"] != "ABS":   # else target absent
            target_code = thisTrial["target"].split('_')
            stim_arg = [win,1,STIM_RAD] 
            if (target_code[0] == "1"): stim_arg.append(_COLOR1)
            elif (target_code[0] == "2"): stim_arg.append(_COLOR2)
            elif (target_code[0] == "3"): stim_arg.append(_COLOR3)
            elif (target_code[0] == "4"): stim_arg.append(_COLOR4)
            else: raise RuntimeError('Stimulus not recognized')
            if (target_code[1] == "1"): stim_arg[1]=1
            elif (target_code[1] == "2"): stim_arg[1]=8
            elif (target_code[1] == "3"): stim_arg[1]=6
            elif (target_code[1] == "4"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP))
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP))
            trialComponents['target'] = NewStimuli(*stim_arg)
        else:
            trialComponents['target'] = None

        for each in thisTrial["distractors"].split(' '):
            dist_code = each.split('_')
            stim_arg=[win,1,STIM_RAD]
            if (dist_code[1] == "1"): stim_arg.append(_COLOR1)
            elif (dist_code[1] == "2"): stim_arg.append(_COLOR2)
            elif (dist_code[1] == "3"): stim_arg.append(_COLOR3)
            elif (dist_code[1] == "4"): stim_arg.append(_COLOR4)
            else: raise RuntimeError('Stimulus not recognized')
            if (dist_code[2] == "1"): stim_arg[1]=1
            elif (dist_code[2] == "2"): stim_arg[1]=8
            elif (dist_code[2] == "3"): stim_arg[1]=6
            elif (dist_code[2] == "4"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            for i in range(int(dist_code[0])):
                conflicted = True
                while conflicted:
                    x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                    y = randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP)
                    conflicted = False
                    if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                        conflicted = True
                    if not conflicted:
                        for j in trialComponents['distractors']:
                            if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                conflicted = True
                trialComponents['distractors'].append(NewStimuli(stim_arg[0],stim_arg[1],stim_arg[2],stim_arg[3],x,y))
                #temp_name = "distractor" + str(i)
                #trialComponents['distractors'].append(visual.ImageStim(win=win, name=temp_name,
                #    image=imagefn, mask=None, ori=0, units='pix',
                #    pos=[x,y], opacity=1, texRes=128, interpolate=True, depth=0.0))
            #for each in trialComponents['distractors']:
            #    each.setSize(each.size*STIM_SCALE)
                    
        # Record starting positions of stimuli for logging
        stimLog = [[0]]
        if trialComponents['target'] is not None:
            stimLog.append([trialComponents['target'].pos[0]])
            stimLog.append([trialComponents['target'].pos[1]])
        for i in range(len(trialComponents['distractors'])):
            stimLog.append([trialComponents['distractors'][i].pos[0]])
            stimLog.append([trialComponents['distractors'][i].pos[1]])
                    
                    
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED
            else:
                if hasattr(value,'status'): value.status = NOT_STARTED
        dist_status = NOT_STARTED # create my own status variable to avoid ~20 checks every cycle
        
        
        #Save initial stimuli heights for movement
        initial = {'distractors':[]}
        for i in range(len(trialComponents['distractors'])):
            initial['distractors'].append(trialComponents['distractors'][i].pos[1])
        if trialComponents['target'] is not None:
            initial['target'] = trialComponents['target'].pos[1]
        
        
#------- READY SCREEN --------
        readyCue.setAutoDraw(True)
        win.flip()
        sleep(READY_TIME)
        readyCue.setAutoDraw(False)
        win.flip()
        
        # Ready the clocks
        t=0; trialClock.reset() #clock 
        frameN=-1
        routineTimer.reset()
        routineTimer.add(MAX_TIME)
        
        #-------Start Routine "trial"-------
        continueRoutine=True
        while continueRoutine and routineTimer.getTime()>0:
            #get current time
            t=trialClock.getTime()
            frameN=frameN+1#number of completed frames (so 0 in first frame)
            
            #*target* update
            if trialComponents['target'] is not None:
                if (t >= 0 and trialComponents['target'].status == NOT_STARTED):
                    trialComponents['target'].tStart=t
                    trialComponents['target'].frameNStart=frameN
                    trialComponents['target'].setAutoDraw(True)
                elif (trialComponents['target'].status == STARTED and t >= MAX_TIME):
                    trialComponents['target'].setAutoDraw(False)
                elif (trialComponents['target'].status == STARTED and expInfo['condition']=='d'):
                    if trialComponents['target'].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['target'] += DISPLAY_DIMENSIONS[1]
                        y = initial['target']-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            for j in trialComponents['distractors']:
                                if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                    conflicted = True
                        trialComponents['target'].setPos([x, y])
                    else:
                        trialComponents['target'].setPos([trialComponents['target'].pos[0], initial['target']-int(t*FALL_RATE)])
            #*dist* update
            if (t >= 0 and dist_status == NOT_STARTED):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(True)
                dist_status = STARTED
            elif (dist_status == STARTED and t >= MAX_TIME):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(False)
                dist_status = FINISHED
            elif (dist_status == STARTED and expInfo['condition']=='d'):
                for each in range(len(trialComponents['distractors'])):
                    if trialComponents['distractors'][each].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['distractors'][each] += DISPLAY_DIMENSIONS[1]
                        y =  initial['distractors'][each]-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                                conflicted = True
                            if not conflicted:
                                for j in trialComponents['distractors']:
                                    if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                        conflicted = True
                        trialComponents['distractors'][each].setPos([x, y])
                    else:
                        trialComponents['distractors'][each].setPos([trialComponents['distractors'][each].pos[0], initial['distractors'][each]-int(t*FALL_RATE)])
                            
            # Record starting positions of stimuli
            if expInfo['condition']=='d':
                stimLog[0].append(t)
                offset = 1
                if trialComponents['target'] is not None:
                    stimLog[1].append(trialComponents['target'].pos[0])
                    stimLog[2].append(trialComponents['target'].pos[1])
                    offset = 3
                for i in range(len(trialComponents['distractors'])):
                    stimLog[i+offset].append(trialComponents['distractors'][i].pos[0])
                    stimLog[i+offset+1].append(trialComponents['distractors'][i].pos[1])
                    offset += 1
                
                
            #*mouse* updates
            if t >= 0 and trialComponents['mouse'].status==NOT_STARTED:
                trialComponents['mouse'].clickReset()
                #keep track of start time/frame for later
                trialComponents['mouse'].tStart=t#underestimates by a little under one frame
                trialComponents['mouse'].frameNStart=frameN#exact frame index
                trialComponents['mouse'].status=STARTED
                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if expInfo['response style'] == 'd':
                    #trialComponents['mouse'].setPos(0,0)
                    autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
                    trialComponents['mouse'].setVisible(True)
            elif trialComponents['mouse'].status==STARTED and t >= MAX_TIME:
                trialComponents['mouse'].status=STOPPED
                if expInfo['response style'] == 'd':
                    trialComponents['mouse'].setVisible(False)
            if trialComponents['mouse'].status==STARTED and sum(response)==0: #only update if started and no previous response has been recorded
                buttons, times = trialComponents['mouse'].getPressed(getTime=True)
                if sum(buttons) == 1:
                    if buttons[0] == 1:
                        if expInfo['response style'] == 'd':
                            #response = [1,0]
                            #rt = times[0]
                            #clickLoc = trialComponents['mouse'].getPos()
                            #trialComponents['mouse'].setVisible(False)
                            #continueRoutine = False
                        
                            #Check if on stimuli
                            on_stim = False
                            if trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                on_stim = True
                            else:
                                for shape in trialComponents['distractors']:
                                    if shape.contains(trialComponents['mouse'].getPos()):
                                        clickLoc = trialComponents['mouse'].getPos()
                                        on_stim = True
                                        break
                            if on_stim:
                                response = [1,0]
                                rt = times[0]
                                clickLoc = trialComponents['mouse'].getPos()
                                trialComponents['mouse'].setVisible(False)
                                continueRoutine = False
                            else: #continue with the trial until they click on something meaningful
                                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                        else: # Target Present Response in Static Stimuli
                            response = [1,0]
                            rt = times[0]
                            continueRoutine = False
                    elif buttons[2] == 1: # Target Absent Response
                        response = [0,1]
                        rt = times[2]
                        continueRoutine = False
                    else: # mouse wheel was pressed
                        event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if sum(buttons) > 0: #Either wheel was pressed or more than one button was pressed. Reset the mouse and continue with the trial.
                    event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            
            #check if all components have finished
            if not continueRoutine: #a component has requested that we end
                routineTimer.reset() #this is the new t0 for non-slip Routines
                break
            continueRoutine=False#will revert to True if at least one component still running
            for key, value in trialComponents.iteritems():
                if key == 'distractors':
                    for thisComponent in value:
                        if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
                else:
                    if hasattr(value,"status") and value.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
            
            #check for quit (the [Esc] key)
            if event.getKeys(["escape"]):
                core.quit()
            
            #refresh the screen
            if continueRoutine:
                win.flip()
                
        #Stop drawing the stimuli
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'setAutoDraw'): thisComponent.setAutoDraw(False)
            else:
                if hasattr(value,'setAutoDraw'): value.setAutoDraw(False)
        
        # FINISH UP RESPONSE FOR STATIC RESPONSE STYLE
        if expInfo['response style'] == 's' and response[0] == 1:
            event.mouseButtons = [0,0,0]
            win.flip() # Go to blank screen
            #trialComponents['mouse'].setPos(0,0)
            if trialComponents['target'] is not None:
                trialComponents['target'].setLineColor((0,0,0))
                trialComponents['target'].setFillColor((255,255,255))
                trialComponents['target'].setEdges(3)
                trialComponents['target'].setVertices(trialComponents['target'].vertices)
                trialComponents['target'].setOri(180)
                trialComponents['target'].setAutoDraw(True)
            for each in trialComponents['distractors']:
                each.setLineColor((0,0,0))
                each.setFillColor((255,255,255))
                each.setEdges(3)
                each.setVertices(each.vertices)
                each.setOri(180)
                each.setAutoDraw(True)
            autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
            trialComponents['mouse'].setVisible(True)
            get_response = True
            while get_response:
                win.flip()
                #check for quit (the [Esc] key)
                if event.getKeys(["escape"]):
                    core.quit()
                #check for response
                if trialComponents['mouse'].getPressed()[0] != 0:
                    #check for click ON STIMULI
                    if trialComponents['target'] is not None and trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                        clickLoc = trialComponents['mouse'].getPos()
                        get_response = False
                    else:
                        for shape in trialComponents['distractors']:
                            if shape.contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                get_response = False
                                break
                else:
                    event.mouseButtons=[0,0,0]
            trialComponents['mouse'].setVisible(False)
            if trialComponents['target'] is not None:
                trialComponents['target'].setAutoDraw(False)
            for each in trialComponents['distractors']:
                each.setAutoDraw(False)
        else:
            win.flip()
            sleep(1.00)
        #End of Routine "trial"
        
        # LOG THE TRIAL
        if thisTrial["target"] != "ABS":
            t1,t2 = thisTrial["target"].split('_')
            if t1 == "1" or t1 == "2":
                c1 = int(thisTrial["color"]) - int(t1)
            elif t1 == "3" or t1 == "4":
                c1 = int(t1) - int(thisTrial["color"])
            else:
                raise RuntimeError("Target color not recognized.")
            if t2 == "1" or t2 == "2":
                c2 = int(thisTrial["shape"]) - int(t2)
            elif t2 == "3" or t2 == "4":
                c2 = int(t2) - int(thisTrial["shape"])
            else:
                raise RuntimeError("Target shape not recognized.")
        else:
            c1,c2 = "NA","NA"
            t1,t2 = 0,0
        logStr = str(expVersion)+'\t'+str(expInfo['date'])+'\t'+str(expInfo['condition'])+'\t'+str(expInfo['response style'])+'\t'+str(expInfo['participant'])+'\t'+str(expInfo['session'])+'\t'+str(thisTrial["type"])+'\t'+str(trialcounter)+'\t'+str(thisTrial["target"])+'\t'+str(t1)+'\t'+str(t2)+'\t'+str(thisTrial["color"])+'\t'+str(thisTrial["shape"])+'\t'+str(thisTrial["distractors"])+'\t'+str(c1)+'\t'+str(c2)+'\t'+str(response[0])+'\t'+str(response[1])+'\t'+str(rt)+'\t'
        
        # Planning to label Channel1 and Channel2 post-hoc in R because the interaction contrast matrix is slightly more complicated
        # if thisTrial.color == 'H':
            # logStr = logStr+"2\t"
        # elif thisTrial.color == 'L':
            # logStr = logStr+"1\t"
        # elif thisTrial.color == 'A':
            # logStr = logStr+"0\t"
        # if thisTrial.shape == 'H':
            # logStr = logStr+"2\t"+str(thisTrial.distractors)+"\t"+str(response[0])+'\t'+str(response[1])+'\t'+str(rt)+'\t'
        # elif thisTrial.shape == 'L':
            # logStr = logStr+"1\t"+str(thisTrial.distractors)+"\t"+str(response[0])+'\t'+str(response[1])+'\t'+str(rt)+'\t'
        # elif thisTrial.shape == 'A':
            # logStr = logStr+"0\t"+str(thisTrial.distractors)+"\t"+str(response[0])+'\t'+str(response[1])+'\t'+str(rt)+'\t'
        if trialComponents['target'] is not None:
            targetPos = trialComponents['target'].pos
            targetSize = trialComponents['target'].size
            logStr = logStr + str(targetPos[0]) + '\t' + str(targetPos[1]) + '\t'
        else:
            logStr = logStr + 'None\tNone\t' 
        logStr = logStr + str(clickLoc[0]) + '\t' + str(clickLoc[1]) + '\t'
        if response[0] == 1:
            if trialComponents['target'] is None:
                logStr = logStr + '0\n'
            #elif (clickLoc[0] < targetPos[0]+.5*targetSize[0]+TOLERANCE and clickLoc[0] > targetPos[0]-.5*targetSize[0]-TOLERANCE and clickLoc[1] < targetPos[1]+.5*targetSize[1]+TOLERANCE and clickLoc[1] > targetPos[1]-.5*targetSize[1]-TOLERANCE):
            elif (trialComponents['target'].contains(clickLoc)):
                    logStr = logStr + '1\n' # correct response
            else:
                logStr = logStr + '0\n' # subject clicked somewhere other than target location
        elif response[1] == 1:
            if trialComponents['target'] is None:
                logStr = logStr + '1\n' # correct response
            else:
                logStr = logStr + '0\n' # absent response when target was not absent
        else:
            logStr = logStr + '-1\n' # trial timed out
        logFile.write(logStr)
        
        #Log the stimuli positions
        for i in range(len(stimLog[0])):
            stimStr = str(expInfo['date']) + "\t" + str(expInfo['participant']) + "\t" + str(expInfo['session']) + "\t" + str(thisTrial["type"]) + "\t" + str(thisTrial["distractors"]) + "\t" + str(trialcounter) + "\t"
            for j in range(len(stimLog)):
                stimStr = stimStr + str(stimLog[j][i]) + "\t"
            stimStr = stimStr.rstrip('\t') + "\n"
            stimFile.write(stimStr)

 
    
def ConjSearchInstructions ():

    sColInstructions = visual.TextStim(win=win, ori=0, name='SCinstructions',
        text='Now you will see a field of objects that could be any combination of red, pink, or purple and diamonds, octagons, or circles.\n\n\nAfter the words "Get Ready..." are displayed, find the RED CIRCLE as quickly as you can.\n\nAfter you find the RED CIRCLE, click the LEFT mouse button.\nIf there is NO red circle, click the RIGHT mouse button.\n\nIf you responded that there was a red circle, you will be asked to click with the LEFT mouse button on where you found the red circle.\nIf you responded that there was no red circle, the trial will progress normally.\n\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    dColInstructions = visual.TextStim(win=win, ori=0, name='DCinstructions',
        text='Now you will see a field of objects that could be any combination of red, pink, or purple and diamonds, octagons, or circles.\n\n\nAfter the words "Get Ready..." are displayed, find the RED CIRCLE as quickly as you can.\n\nAfter you find the RED CIRCLE, click on it with the LEFT mouse button.\n\nIf there is NO red circle, click the RIGHT mouse button anywhere.\n\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix",height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    exampleStim = [NewStimuli(win, 4, STIM_RAD, _TARGET_COLOR, -500, 250, orientation=22.5),
        NewStimuli(win, 4, STIM_RAD, _LOW_COLOR, -500+1*3*STIM_RAD, 250, orientation=22.5),NewStimuli(win, 4, STIM_RAD, _HIGH_COLOR, -500+2*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 8, STIM_RAD, _TARGET_COLOR, -500+3*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 8, STIM_RAD, _LOW_COLOR, -500+4*3*STIM_RAD, 250, orientation=22.5),NewStimuli(win, 8, STIM_RAD, _HIGH_COLOR, -500+5*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 1, STIM_RAD, _TARGET_COLOR, -500+6*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 1, STIM_RAD, _LOW_COLOR, -500+7*3*STIM_RAD, 250, orientation=22.5),NewStimuli(win, 1, STIM_RAD, _HIGH_COLOR, -500+8*3*STIM_RAD, 250, orientation=22.5)]
    
#------Prepare to start Routine"Instructions"-------
    t=0; instructionsClock.reset() #clock 
    frameN=-1
    InstructionsComponents={}
    if (expInfo['response style']=='s'):
        InstructionsComponents['instructions']=(sColInstructions)
    elif (expInfo['response style']=='d'):
        InstructionsComponents['instructions']=(dColInstructions)
    else:
        raise RuntimeError('Failed to Initialise Instructions')
    InstructionsComponents['mouse']=(mouse)
    for key,thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED

    #-------Start Routine "Instructions"-------
    continueRoutine=True
    while continueRoutine:
        #get current time
        t=instructionsClock.getTime()
        frameN=frameN+1#number of completed frames (so 0 in first frame)
        #update/draw components on each frame
        
        #*text* updates
        if t>=0.0 and InstructionsComponents['instructions'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['instructions'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['instructions'].frameNStart=frameN#exact frame index
            InstructionsComponents['instructions'].setAutoDraw(True)
            for s in exampleStim:
                s.setAutoDraw(True)
        #*mouse* updates
        if t>=0.0 and InstructionsComponents['mouse'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['mouse'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['mouse'].frameNStart=frameN#exact frame index
            InstructionsComponents['mouse'].status=STARTED
            event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
        if InstructionsComponents['mouse'].status==STARTED:#only update if started and not stopped!
            buttons = mouse.getPressed()
            if sum(buttons)>0:#ie if any button is pressed
                #abort routine on response
                continueRoutine=False
        
        #check if all components have finished
        if not continueRoutine: #a component has requested that we end
            routineTimer.reset() #this is the new t0 for non-slip Routines
            break
        continueRoutine=False#will revert to True if at least one component still running
        for key, thisComponent in InstructionsComponents.iteritems():
            if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                continueRoutine=True; break#at least one component has not yet finished
        
        #check for quit (the [Esc] key)
        if event.getKeys(["escape"]):
            core.quit()
        
        #refresh the screen
        if continueRoutine:#don't flip if this routine is over or we'll get a blank screen
            win.flip()

    #End of Routine "Instructions"
    for key, thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,"setAutoDraw"): thisComponent.setAutoDraw(False)
        for s in exampleStim:
            s.setAutoDraw(False)
    #Blank the Instructions Screen
    win.flip()
    
    #### Practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    sixteenTrialWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    sixteenTrialWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    
    #### Begin Dynamic Instructions ####
    instrConds = ["RC23VD","RC23VO","RC23VC","RC23MD","RC23MO","RC23MC","RC23RD","RC23RO","AB24VD","AB24VO","AB24VC","AB24MD","AB24MO","AB24MC","AB24RD","AB24RO"]
    shuffle(instrConds)
    for trial in instrConds:
    
        response = [0,0]
        rt = -1
        clickLoc = [None,None]
        
        trialComponents = {'mouse':mouse, 'distractors':[]}
        #load stimuli
        if trial[0:2] != "AB":   # else target absent
            stim_arg = [win,1,STIM_RAD] 
            if (trial[0] == "R"): stim_arg.append(_TARGET_COLOR)
            elif (trial[0] == "M"): stim_arg.append(_LOW_COLOR)
            elif (trial[0] == "V"): stim_arg.append(_HIGH_COLOR)
            else: raise RuntimeError('Stimulus not recognized')
            if (trial[1] == "C"): stim_arg[1]=1
            elif (trial[1] == "O"): stim_arg[1]=8
            elif (trial[1] == "D"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP))
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP))
            trialComponents['target'] = NewStimuli(*stim_arg)
            ta = trial[0:2]
        else:
            trialComponents['target'] = None
            ta = "ABS"
        trial = trial[2:]
        
        stim_arg=[win,1,STIM_RAD]
        if (trial[2] == "R"): stim_arg.append(_TARGET_COLOR)
        elif (trial[2] == "M"): stim_arg.append(_LOW_COLOR)
        elif (trial[2] == "V"): stim_arg.append(_HIGH_COLOR)
        else: raise RuntimeError('Stimulus not recognized')
        if (trial[3] == "C"): stim_arg[1]=1
        elif (trial[3] == "O"): stim_arg[1]=8
        elif (trial[3] == "D"): stim_arg[1]=4
        else: raise RuntimeError('Stimulus not recognized')
        for i in range(int(trial[0:2])):
            conflicted = True
            while conflicted:
                x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                y = randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP)
                conflicted = False
                if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                    conflicted = True
                if not conflicted:
                    for j in trialComponents['distractors']:
                        if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                            conflicted = True
            trialComponents['distractors'].append(NewStimuli(stim_arg[0],stim_arg[1],stim_arg[2],stim_arg[3],x,y))
                    
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED
            else:
                if hasattr(value,'status'): value.status = NOT_STARTED
        dist_status = NOT_STARTED # create my own status variable to avoid ~20 checks every cycle
        
        #Save initial stimuli heights for movement
        initial = {'distractors':[]}
        for i in range(len(trialComponents['distractors'])):
            initial['distractors'].append(trialComponents['distractors'][i].pos[1])
        if trialComponents['target'] is not None:
            initial['target'] = trialComponents['target'].pos[1]
        
        
#------- READY SCREEN --------
        readyCue.setAutoDraw(True)
        win.flip()
        sleep(READY_TIME)
        readyCue.setAutoDraw(False)
        win.flip()
        
        # Ready the clocks
        t=0; trialClock.reset() #clock 
        frameN=-1
        routineTimer.reset()
        routineTimer.add(MAX_TIME)
        
        #-------Start Routine "trial"-------
        continueRoutine=True
        while continueRoutine and routineTimer.getTime()>0:
            #get current time
            t=trialClock.getTime()
            frameN=frameN+1#number of completed frames (so 0 in first frame)
            
            #*target* update
            if trialComponents['target'] is not None:
                if (t >= 0 and trialComponents['target'].status == NOT_STARTED):
                    trialComponents['target'].tStart=t
                    trialComponents['target'].frameNStart=frameN
                    trialComponents['target'].setAutoDraw(True)
                elif (trialComponents['target'].status == STARTED and t >= MAX_TIME):
                    trialComponents['target'].setAutoDraw(False)
                elif (trialComponents['target'].status == STARTED and expInfo['condition']=='d'):
                    if trialComponents['target'].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['target'] += DISPLAY_DIMENSIONS[1]
                        y = initial['target']-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            for j in trialComponents['distractors']:
                                if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                    conflicted = True
                        trialComponents['target'].setPos([x, y])
                    else:
                        trialComponents['target'].setPos([trialComponents['target'].pos[0], initial['target']-int(t*FALL_RATE)])
            #*dist* update
            if (t >= 0 and dist_status == NOT_STARTED):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(True)
                dist_status = STARTED
            elif (dist_status == STARTED and t >= MAX_TIME):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(False)
                dist_status = FINISHED
            elif (dist_status == STARTED and expInfo['condition']=='d'):
                for each in range(len(trialComponents['distractors'])):
                    if trialComponents['distractors'][each].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['distractors'][each] += DISPLAY_DIMENSIONS[1]
                        y =  initial['distractors'][each]-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                                conflicted = True
                            if not conflicted:
                                for j in trialComponents['distractors']:
                                    if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                        conflicted = True
                        trialComponents['distractors'][each].setPos([x, y])
                    else:
                        trialComponents['distractors'][each].setPos([trialComponents['distractors'][each].pos[0], initial['distractors'][each]-int(t*FALL_RATE)])
                            
            # Record starting positions of stimuli
            if expInfo['condition']=='d':
                stimLog[0].append(t)
                offset = 1
                if trialComponents['target'] is not None:
                    stimLog[1].append(trialComponents['target'].pos[0])
                    stimLog[2].append(trialComponents['target'].pos[1])
                    offset = 3
                for i in range(len(trialComponents['distractors'])):
                    stimLog[i+offset].append(trialComponents['distractors'][i].pos[0])
                    stimLog[i+offset+1].append(trialComponents['distractors'][i].pos[1])
                    offset += 1
                
                
            #*mouse* updates
            if t >= 0 and trialComponents['mouse'].status==NOT_STARTED:
                trialComponents['mouse'].clickReset()
                #keep track of start time/frame for later
                trialComponents['mouse'].tStart=t#underestimates by a little under one frame
                trialComponents['mouse'].frameNStart=frameN#exact frame index
                trialComponents['mouse'].status=STARTED
                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if expInfo['response style'] == 'd':
                    #trialComponents['mouse'].setPos(0,0)
                    autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
                    trialComponents['mouse'].setVisible(True)
            elif trialComponents['mouse'].status==STARTED and t >= MAX_TIME:
                trialComponents['mouse'].status=STOPPED
                if expInfo['response style'] == 'd':
                    trialComponents['mouse'].setVisible(False)
            if trialComponents['mouse'].status==STARTED and sum(response)==0: #only update if started and no previous response has been recorded
                buttons, times = trialComponents['mouse'].getPressed(getTime=True)
                if sum(buttons) == 1:
                    if buttons[0] == 1:
                        if expInfo['response style'] == 'd':
                        
                            #Check if on stimuli
                            on_stim = False
                            if trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                on_stim = True
                            else:
                                for shape in trialComponents['distractors']:
                                    if shape.contains(trialComponents['mouse'].getPos()):
                                        clickLoc = trialComponents['mouse'].getPos()
                                        on_stim = True
                                        break
                            if on_stim:
                                response = [1,0]
                                rt = times[0]
                                clickLoc = trialComponents['mouse'].getPos()
                                trialComponents['mouse'].setVisible(False)
                                continueRoutine = False
                            else: #continue with the trial until they click on something meaningful
                                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                        else: # Target Present Response in Static Stimuli
                            response = [1,0]
                            rt = times[0]
                            continueRoutine = False
                    elif buttons[2] == 1: # Target Absent Response
                        response = [0,1]
                        rt = times[2]
                        continueRoutine = False
                    else: # mouse wheel was pressed
                        event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if sum(buttons) > 0: #Either wheel was pressed or more than one button was pressed. Reset the mouse and continue with the trial.
                    event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            
            #check if all components have finished
            if not continueRoutine: #a component has requested that we end
                routineTimer.reset() #this is the new t0 for non-slip Routines
                break
            continueRoutine=False#will revert to True if at least one component still running
            for key, value in trialComponents.iteritems():
                if key == 'distractors':
                    for thisComponent in value:
                        if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
                else:
                    if hasattr(value,"status") and value.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
            
            #check for quit (the [Esc] key)
            if event.getKeys(["escape"]):
                core.quit()
            
            #refresh the screen
            if continueRoutine:
                win.flip()
                
        #Stop drawing the stimuli
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'setAutoDraw'): thisComponent.setAutoDraw(False)
            else:
                if hasattr(value,'setAutoDraw'): value.setAutoDraw(False)
        
        # FINISH UP RESPONSE FOR STATIC RESPONSE STYLE
        if expInfo['response style'] == 's' and response[0] == 1:
            event.mouseButtons = [0,0,0]
            win.flip() # Go to blank screen
            if trialComponents['target'] is not None:
                targetDecoy = NewStimuli(win, 3, STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1], orientation=180)
                targetDecoy.setLineColor((0,0,0))
                targetDecoy.setAutoDraw(True)
            distDecoys = []
            for each in trialComponents['distractors']:
                distDecoys.append(NewStimuli(win, 3, STIM_RAD, (255,255,255), each.pos[0], each.pos[1], orientation=180))
                distDecoys[-1].setLineColor((0,0,0))
                distDecoys[-1].setAutoDraw(True)
            autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
            trialComponents['mouse'].setVisible(True)
            get_response = True
            while get_response:
                win.flip()
                #check for quit (the [Esc] key)
                if event.getKeys(["escape"]):
                    core.quit()
                #check for response
                if trialComponents['mouse'].getPressed()[0] != 0:
                    #check for click ON STIMULI
                    if trialComponents['target'] is not None and targetDecoy.contains(trialComponents['mouse'].getPos()):
                        clickLoc = trialComponents['mouse'].getPos()
                        get_response = False
                    else:
                        for shape in distDecoys:
                            if shape.contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                get_response = False
                                break
                else:
                    event.mouseButtons=[0,0,0]
            trialComponents['mouse'].setVisible(False)
            if trialComponents['target'] is not None:
                targetDecoy.setAutoDraw(False)
            for each in distDecoys:
                each.setAutoDraw(False)
        else:
            win.flip()
            sleep(1.00)
        #End of Routine "trial"
        
        # PROVIDE FEEDBACK
        # If they were correct just give em a pat on the back
        if ta == "ABS" and response[1] == 1:
            feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
            feedback.setAutoDraw(True)
            event.mouseButtons=[0,0,0]
            while trialComponents['mouse'].getPressed()[0] == 0:
                win.flip()
            trialComponents['mouse'].clickReset()
            feedback.setAutoDraw(False)
            win.flip()
        else:
            try:
                targetDecoy
                if ta == "RC" and response[0] == 1 and targetDecoy.contains(clickLoc):
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    win.flip()
                else:
                    raise NameError
            except NameError:
                # If they were wrong show them the original stimuli
                #if expInfo['response style'] == 's' and response[0] == 1:
                #    if trialComponents['target'] is not None:
                #        targetDecoy.setAutoDraw(False)
                #    for shape in distDecoys:
                #        shape.setAutoDraw(False)
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(True)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(True)
                    
                if ta == "ABS":
                    # Wrong - there is no target
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. There is no target on this trial.',
                        units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    #win.flip()
                else:
                    # Wrong - the target is here
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                            units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #if trialComponents['target'].pos[1] > 0:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]-400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #else:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]+400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    focus = NewStimuli(win, 1, 2*STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1])
                    focus.setLineColor((0,0,0))
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        feedback.draw(win)
                        focus.draw(win)
                        trialComponents['target'].draw(win) # Anticipating needing this
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    focus.setAutoDraw(False)
                    #win.flip()
                
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(False)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(False)
                win.flip()
                
    #### End of practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    endOfPracticeWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    endOfPracticeWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    
def SingletonSearchInstructions ():

    sColInstructions = visual.TextStim(win=win, ori=0, name='SCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of colored shapes. Examples are below:\n\n\nOne of the objects may be different from the others in its color or shape.\n\nIf there is a different object present, click the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button.\n\nIf you responded that there was a different object present, you will be asked to click with the LEFT mouse button where you found it.\n\nIf you responded that all the objects were the same, the trial will progress normally.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    dColInstructions = visual.TextStim(win=win, ori=0, name='DCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of colored shapes.\nExamples are below:\n\n\nOne of the objects may be different from the others in its color or shape.\n\nIf there is a different object present, click on it with the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button anywhere.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix",height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    exampleStim = [NewStimuli(win, 1, STIM_RAD, _COLOR1, -500, 275, orientation=22.5), NewStimuli(win, 1, STIM_RAD, _COLOR2, -500+1*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 1, STIM_RAD, _COLOR3, -500+2*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 1, STIM_RAD, _COLOR4, -500+3*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 8, STIM_RAD, _COLOR1, -500+4*3*STIM_RAD, 275, orientation=22.5),NewStimuli(win, 8, STIM_RAD, _COLOR2, -500+5*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 8, STIM_RAD, _COLOR3, -500+6*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 8, STIM_RAD, _COLOR4, -500+7*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 6, STIM_RAD, _COLOR1, -500+8*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 6, STIM_RAD, _COLOR2, -500+9*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 6, STIM_RAD, _COLOR3, -500+10*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 6, STIM_RAD, _COLOR4, -500+11*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 4, STIM_RAD, _COLOR1, -500+12*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 4, STIM_RAD, _COLOR2, -500+13*3*STIM_RAD, 275, orientation=22.5),
        NewStimuli(win, 4, STIM_RAD, _COLOR3, -500+14*3*STIM_RAD, 275, orientation=22.5), NewStimuli(win, 4, STIM_RAD, _COLOR4, -500+15*3*STIM_RAD, 275, orientation=22.5)]
    
#------Prepare to start Routine"Instructions"-------
    t=0; instructionsClock.reset() #clock 
    frameN=-1
    InstructionsComponents={}
    if (expInfo['response style']=='s'):
        InstructionsComponents['instructions']=(sColInstructions)
    elif (expInfo['response style']=='d'):
        InstructionsComponents['instructions']=(dColInstructions)
    else:
        raise RuntimeError('Failed to Initialise Instructions')
    InstructionsComponents['mouse']=(mouse)
    for key,thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED

    #-------Start Routine "Instructions"-------
    continueRoutine=True
    while continueRoutine:
        #get current time
        t=instructionsClock.getTime()
        frameN=frameN+1#number of completed frames (so 0 in first frame)
        #update/draw components on each frame
        
        #*text* updates
        if t>=0.0 and InstructionsComponents['instructions'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['instructions'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['instructions'].frameNStart=frameN#exact frame index
            InstructionsComponents['instructions'].setAutoDraw(True)
            for s in exampleStim:
                s.setAutoDraw(True)
        #*mouse* updates
        if t>=0.0 and InstructionsComponents['mouse'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['mouse'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['mouse'].frameNStart=frameN#exact frame index
            InstructionsComponents['mouse'].status=STARTED
            event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
        if InstructionsComponents['mouse'].status==STARTED:#only update if started and not stopped!
            buttons = mouse.getPressed()
            if sum(buttons)>0:#ie if any button is pressed
                #abort routine on response
                continueRoutine=False
        
        #check if all components have finished
        if not continueRoutine: #a component has requested that we end
            routineTimer.reset() #this is the new t0 for non-slip Routines
            break
        continueRoutine=False#will revert to True if at least one component still running
        for key, thisComponent in InstructionsComponents.iteritems():
            if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                continueRoutine=True; break#at least one component has not yet finished
        
        #check for quit (the [Esc] key)
        if event.getKeys(["escape"]):
            core.quit()
        
        #refresh the screen
        if continueRoutine:#don't flip if this routine is over or we'll get a blank screen
            win.flip()

    #End of Routine "Instructions"
    for key, thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,"setAutoDraw"): thisComponent.setAutoDraw(False)
        for s in exampleStim:
            s.setAutoDraw(False)
    #Blank the Instructions Screen
    win.flip()
    
    #### Practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    sixteenTrialWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    sixteenTrialWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    
    #### Begin Dynamic Instructions ####
    possStimuli = ("1_1", "1_2", "1_3", "1_4", "2_1", "2_2", "2_3", "2_4", "3_1", "3_2", "3_3", "3_4", "4_1", "4_2", "4_3", "4_4")
    instrConds = [0,1] * 8 # use this to specify target presence
    #instrConds = ["RC23VD","RC23VO","RC23VC","RC23MD","RC23MO","RC23MC","RC23RD","RC23RO","AB24VD","AB24VO","AB24VC","AB24MD","AB24MO","AB24MC","AB24RD","AB24RO"]
    shuffle(instrConds)
    
    for trial in instrConds:
    
        response = [0,0]
        rt = -1
        clickLoc = [None,None]
        
        trialComponents = {'mouse':mouse, 'distractors':[]}
        #load stimuli
        
        #pick a target
        #pick a distractor
        #fill
        
        if trial == 1: # Target Present
            targetType = randint(len(possStimuli))
            distType = choice([x for i,x in enumerate(range(len(possStimuli))) if i!=targetType])
            target_code = possStimuli[targetType].split('_')
            stim_arg = [win,1,STIM_RAD] 
            if (target_code[0] == "1"): stim_arg.append(_COLOR1)
            elif (target_code[0] == "2"): stim_arg.append(_COLOR2)
            elif (target_code[0] == "3"): stim_arg.append(_COLOR3)
            elif (target_code[0] == "4"): stim_arg.append(_COLOR4)
            else: raise RuntimeError('Stimulus not recognized')
            if (target_code[1] == "1"): stim_arg[1]=1
            elif (target_code[1] == "2"): stim_arg[1]=8
            elif (target_code[1] == "3"): stim_arg[1]=6
            elif (target_code[1] == "4"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP))
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP))
            trialComponents['target'] = NewStimuli(*stim_arg)
        else: # Target Absent
            trialComponents['target'] = None
            distType = randint(len(possStimuli))
        
        
        dist_code = possStimuli[distType].split('_')
        stim_arg = [win,1,STIM_RAD] 
        if (dist_code[0] == "1"): stim_arg.append(_COLOR1)
        elif (dist_code[0] == "2"): stim_arg.append(_COLOR2)
        elif (dist_code[0] == "3"): stim_arg.append(_COLOR3)
        elif (dist_code[0] == "4"): stim_arg.append(_COLOR4)
        else: raise RuntimeError('Stimulus not recognized')
        if (dist_code[1] == "1"): stim_arg[1]=1
        elif (dist_code[1] == "2"): stim_arg[1]=8
        elif (dist_code[1] == "3"): stim_arg[1]=6
        elif (dist_code[1] == "4"): stim_arg[1]=4
        else: raise RuntimeError('Stimulus not recognized')
        for i in range(NUM_DISTRACTORS + 1 - trial):
            conflicted = True
            while conflicted:
                x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                y = randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP)
                conflicted = False
                if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                    conflicted = True
                if not conflicted:
                    for j in trialComponents['distractors']:
                        if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                            conflicted = True
            trialComponents['distractors'].append(NewStimuli(stim_arg[0],stim_arg[1],stim_arg[2],stim_arg[3],x,y))
                    
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED
            else:
                if hasattr(value,'status'): value.status = NOT_STARTED
        dist_status = NOT_STARTED # create my own status variable to avoid ~20 checks every cycle
        
        #Save initial stimuli heights for movement
        initial = {'distractors':[]}
        for i in range(len(trialComponents['distractors'])):
            initial['distractors'].append(trialComponents['distractors'][i].pos[1])
        if trialComponents['target'] is not None:
            initial['target'] = trialComponents['target'].pos[1]
        
        
#------- READY SCREEN --------
        readyCue.setAutoDraw(True)
        win.flip()
        sleep(READY_TIME)
        readyCue.setAutoDraw(False)
        win.flip()
        
        # Ready the clocks
        t=0; trialClock.reset() #clock 
        frameN=-1
        routineTimer.reset()
        routineTimer.add(MAX_TIME)
        
        #-------Start Routine "trial"-------
        continueRoutine=True
        while continueRoutine and routineTimer.getTime()>0:
            #get current time
            t=trialClock.getTime()
            frameN=frameN+1#number of completed frames (so 0 in first frame)
            
            #*target* update
            if trialComponents['target'] is not None:
                if (t >= 0 and trialComponents['target'].status == NOT_STARTED):
                    trialComponents['target'].tStart=t
                    trialComponents['target'].frameNStart=frameN
                    trialComponents['target'].setAutoDraw(True)
                elif (trialComponents['target'].status == STARTED and t >= MAX_TIME):
                    trialComponents['target'].setAutoDraw(False)
                elif (trialComponents['target'].status == STARTED and expInfo['condition']=='d'):
                    if trialComponents['target'].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['target'] += DISPLAY_DIMENSIONS[1]
                        y = initial['target']-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            for j in trialComponents['distractors']:
                                if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                    conflicted = True
                        trialComponents['target'].setPos([x, y])
                    else:
                        trialComponents['target'].setPos([trialComponents['target'].pos[0], initial['target']-int(t*FALL_RATE)])
            #*dist* update
            if (t >= 0 and dist_status == NOT_STARTED):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(True)
                dist_status = STARTED
            elif (dist_status == STARTED and t >= MAX_TIME):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(False)
                dist_status = FINISHED
            elif (dist_status == STARTED and expInfo['condition']=='d'):
                for each in range(len(trialComponents['distractors'])):
                    if trialComponents['distractors'][each].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['distractors'][each] += DISPLAY_DIMENSIONS[1]
                        y =  initial['distractors'][each]-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                                conflicted = True
                            if not conflicted:
                                for j in trialComponents['distractors']:
                                    if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                        conflicted = True
                        trialComponents['distractors'][each].setPos([x, y])
                    else:
                        trialComponents['distractors'][each].setPos([trialComponents['distractors'][each].pos[0], initial['distractors'][each]-int(t*FALL_RATE)])
                            
            # Record starting positions of stimuli
            if expInfo['condition']=='d':
                stimLog[0].append(t)
                offset = 1
                if trialComponents['target'] is not None:
                    stimLog[1].append(trialComponents['target'].pos[0])
                    stimLog[2].append(trialComponents['target'].pos[1])
                    offset = 3
                for i in range(len(trialComponents['distractors'])):
                    stimLog[i+offset].append(trialComponents['distractors'][i].pos[0])
                    stimLog[i+offset+1].append(trialComponents['distractors'][i].pos[1])
                    offset += 1
                
                
            #*mouse* updates
            if t >= 0 and trialComponents['mouse'].status==NOT_STARTED:
                trialComponents['mouse'].clickReset()
                #keep track of start time/frame for later
                trialComponents['mouse'].tStart=t#underestimates by a little under one frame
                trialComponents['mouse'].frameNStart=frameN#exact frame index
                trialComponents['mouse'].status=STARTED
                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if expInfo['response style'] == 'd':
                    #trialComponents['mouse'].setPos(0,0)
                    autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
                    trialComponents['mouse'].setVisible(True)
            elif trialComponents['mouse'].status==STARTED and t >= MAX_TIME:
                trialComponents['mouse'].status=STOPPED
                if expInfo['response style'] == 'd':
                    trialComponents['mouse'].setVisible(False)
            if trialComponents['mouse'].status==STARTED and sum(response)==0: #only update if started and no previous response has been recorded
                buttons, times = trialComponents['mouse'].getPressed(getTime=True)
                if sum(buttons) == 1:
                    if buttons[0] == 1:
                        if expInfo['response style'] == 'd':
                        
                            #Check if on stimuli
                            on_stim = False
                            if trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                on_stim = True
                            else:
                                for shape in trialComponents['distractors']:
                                    if shape.contains(trialComponents['mouse'].getPos()):
                                        clickLoc = trialComponents['mouse'].getPos()
                                        on_stim = True
                                        break
                            if on_stim:
                                response = [1,0]
                                rt = times[0]
                                clickLoc = trialComponents['mouse'].getPos()
                                trialComponents['mouse'].setVisible(False)
                                continueRoutine = False
                            else: #continue with the trial until they click on something meaningful
                                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                        else: # Target Present Response in Static Stimuli
                            response = [1,0]
                            rt = times[0]
                            continueRoutine = False
                    elif buttons[2] == 1: # Target Absent Response
                        response = [0,1]
                        rt = times[2]
                        continueRoutine = False
                    else: # mouse wheel was pressed
                        event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if sum(buttons) > 0: #Either wheel was pressed or more than one button was pressed. Reset the mouse and continue with the trial.
                    event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            
            #check if all components have finished
            if not continueRoutine: #a component has requested that we end
                routineTimer.reset() #this is the new t0 for non-slip Routines
                break
            continueRoutine=False#will revert to True if at least one component still running
            for key, value in trialComponents.iteritems():
                if key == 'distractors':
                    for thisComponent in value:
                        if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
                else:
                    if hasattr(value,"status") and value.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
            
            #check for quit (the [Esc] key)
            if event.getKeys(["escape"]):
                core.quit()
            
            #refresh the screen
            if continueRoutine:
                win.flip()
                
        #Stop drawing the stimuli
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'setAutoDraw'): thisComponent.setAutoDraw(False)
            else:
                if hasattr(value,'setAutoDraw'): value.setAutoDraw(False)
        
        # FINISH UP RESPONSE FOR STATIC RESPONSE STYLE
        if expInfo['response style'] == 's' and response[0] == 1:
            event.mouseButtons = [0,0,0]
            win.flip() # Go to blank screen
            if trialComponents['target'] is not None:
                targetDecoy = NewStimuli(win, 3, STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1], orientation=180)
                targetDecoy.setLineColor((0,0,0))
                targetDecoy.setAutoDraw(True)
            distDecoys = []
            for each in trialComponents['distractors']:
                distDecoys.append(NewStimuli(win, 3, STIM_RAD, (255,255,255), each.pos[0], each.pos[1], orientation=180))
                distDecoys[-1].setLineColor((0,0,0))
                distDecoys[-1].setAutoDraw(True)
            autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
            trialComponents['mouse'].setVisible(True)
            get_response = True
            while get_response:
                win.flip()
                #check for quit (the [Esc] key)
                if event.getKeys(["escape"]):
                    core.quit()
                #check for response
                if trialComponents['mouse'].getPressed()[0] != 0:
                    #check for click ON STIMULI
                    if trialComponents['target'] is not None and targetDecoy.contains(trialComponents['mouse'].getPos()):
                        clickLoc = trialComponents['mouse'].getPos()
                        get_response = False
                    else:
                        for shape in distDecoys:
                            if shape.contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                get_response = False
                                break
                else:
                    event.mouseButtons=[0,0,0]
            trialComponents['mouse'].setVisible(False)
            if trialComponents['target'] is not None:
                targetDecoy.setAutoDraw(False)
            for each in distDecoys:
                each.setAutoDraw(False)
        else:
            win.flip()
            sleep(1.00)
        #End of Routine "trial"
        
        # PROVIDE FEEDBACK
        # If they were correct just give em a pat on the back
        if trial == 0 and response[1] == 1:
            feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
            feedback.setAutoDraw(True)
            event.mouseButtons=[0,0,0]
            while trialComponents['mouse'].getPressed()[0] == 0:
                win.flip()
            trialComponents['mouse'].clickReset()
            feedback.setAutoDraw(False)
            win.flip()
        else:
            try:
                targetDecoy
                if trial == 1 and response[0] == 1 and targetDecoy.contains(clickLoc):
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    win.flip()
                else:
                    raise NameError
            except NameError:
                # If they were wrong show them the original stimuli
                #if expInfo['response style'] == 's' and response[0] == 1:
                #    if trialComponents['target'] is not None:
                #        targetDecoy.setAutoDraw(False)
                #    for shape in distDecoys:
                #        shape.setAutoDraw(False)
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(True)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(True)
                    
                if trial == 0:
                    # Wrong - there is no target
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. There is no target on this trial.',
                        units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    #win.flip()
                else:
                    # Wrong - the target is here
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                            units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #if trialComponents['target'].pos[1] > 0:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]-400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #else:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]+400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    focus = NewStimuli(win, 1, 2*STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1])
                    focus.setLineColor((0,0,0))
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        feedback.draw(win)
                        focus.draw(win)
                        trialComponents['target'].draw(win) # Anticipating needing this
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    focus.setAutoDraw(False)
                    #win.flip()
                
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(False)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(False)
                win.flip()
                
    #### End of practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    endOfPracticeWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    endOfPracticeWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]

def ColorCapInstructions ():

    sColInstructions = visual.TextStim(win=win, ori=0, name='SCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of different colored circles. Examples are below:\n\n\nOne of the objects may be different from the others in its color.\n\nIf there is a different object present, click the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button.\n\nIf you responded that there was a different object present, you will be asked to click with the LEFT mouse button where you found it.\n\nIf you responded that all the objects were the same, the trial will progress normally.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    dColInstructions = visual.TextStim(win=win, ori=0, name='DCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of different colored circles.\nExamples are below:\n\n\nOne of the objects may be different from the others in its color.\n\nIf there is a different object present, click on it with the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button anywhere.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix",height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    exampleStim = [NewStimuli(win, 1, STIM_RAD, _COLOR1, -500, 250, orientation=22.5), NewStimuli(win, 1, STIM_RAD, _COLOR2, -500+1*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 1, STIM_RAD, _COLOR3, -500+2*3*STIM_RAD, 250, orientation=22.5), NewStimuli(win, 1, STIM_RAD, _COLOR4, -500+3*3*STIM_RAD, 250, orientation=22.5)]
    
#------Prepare to start Routine"Instructions"-------
    t=0; instructionsClock.reset() #clock 
    frameN=-1
    InstructionsComponents={}
    if (expInfo['response style']=='s'):
        InstructionsComponents['instructions']=(sColInstructions)
    elif (expInfo['response style']=='d'):
        InstructionsComponents['instructions']=(dColInstructions)
    else:
        raise RuntimeError('Failed to Initialise Instructions')
    InstructionsComponents['mouse']=(mouse)
    for key,thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED

    #-------Start Routine "Instructions"-------
    continueRoutine=True
    while continueRoutine:
        #get current time
        t=instructionsClock.getTime()
        frameN=frameN+1#number of completed frames (so 0 in first frame)
        #update/draw components on each frame
        
        #*text* updates
        if t>=0.0 and InstructionsComponents['instructions'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['instructions'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['instructions'].frameNStart=frameN#exact frame index
            InstructionsComponents['instructions'].setAutoDraw(True)
            for s in exampleStim:
                s.setAutoDraw(True)
        #*mouse* updates
        if t>=0.0 and InstructionsComponents['mouse'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['mouse'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['mouse'].frameNStart=frameN#exact frame index
            InstructionsComponents['mouse'].status=STARTED
            event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
        if InstructionsComponents['mouse'].status==STARTED:#only update if started and not stopped!
            buttons = mouse.getPressed()
            if sum(buttons)>0:#ie if any button is pressed
                #abort routine on response
                continueRoutine=False
        
        #check if all components have finished
        if not continueRoutine: #a component has requested that we end
            routineTimer.reset() #this is the new t0 for non-slip Routines
            break
        continueRoutine=False#will revert to True if at least one component still running
        for key, thisComponent in InstructionsComponents.iteritems():
            if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                continueRoutine=True; break#at least one component has not yet finished
        
        #check for quit (the [Esc] key)
        if event.getKeys(["escape"]):
            core.quit()
        
        #refresh the screen
        if continueRoutine:#don't flip if this routine is over or we'll get a blank screen
            win.flip()

    #End of Routine "Instructions"
    for key, thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,"setAutoDraw"): thisComponent.setAutoDraw(False)
        for s in exampleStim:
            s.setAutoDraw(False)
    #Blank the Instructions Screen
    win.flip()
    
    #### Practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    sixteenTrialWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    sixteenTrialWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    
    #### Begin Dynamic Instructions ####
    possStimuli = ("1_1", "2_1", "3_1", "4_1")
    instrConds = [0,1] * 4 # use this to specify target presence
    targetOrder = range(len(possStimuli))
    #instrConds = ["RC23VD","RC23VO","RC23VC","RC23MD","RC23MO","RC23MC","RC23RD","RC23RO","AB24VD","AB24VO","AB24VC","AB24MD","AB24MO","AB24MC","AB24RD","AB24RO"]
    shuffle(instrConds); shuffle(targetOrder)
    
    for trial in instrConds:
    
        response = [0,0]
        rt = -1
        clickLoc = [None,None]
        
        trialComponents = {'mouse':mouse, 'distractors':[]}
        #load stimuli
        if trial == 1: # Target Present
            targetType = targetOrder.pop()
            distType = choice([x for i,x in enumerate(range(len(possStimuli))) if i!=targetType])
            target_code = possStimuli[targetType].split('_')
            stim_arg = [win,1,STIM_RAD] 
            if (target_code[0] == "1"): stim_arg.append(_COLOR1)
            elif (target_code[0] == "2"): stim_arg.append(_COLOR2)
            elif (target_code[0] == "3"): stim_arg.append(_COLOR3)
            elif (target_code[0] == "4"): stim_arg.append(_COLOR4)
            else: raise RuntimeError('Stimulus not recognized')
            if (target_code[1] == "1"): stim_arg[1]=1
            elif (target_code[1] == "2"): stim_arg[1]=8
            elif (target_code[1] == "3"): stim_arg[1]=6
            elif (target_code[1] == "4"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP))
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP))
            trialComponents['target'] = NewStimuli(*stim_arg)
        else: # Target Absent
            trialComponents['target'] = None
            distType = randint(len(possStimuli))
        
        
        dist_code = possStimuli[distType].split('_')
        stim_arg = [win,1,STIM_RAD] 
        if (dist_code[0] == "1"): stim_arg.append(_COLOR1)
        elif (dist_code[0] == "2"): stim_arg.append(_COLOR2)
        elif (dist_code[0] == "3"): stim_arg.append(_COLOR3)
        elif (dist_code[0] == "4"): stim_arg.append(_COLOR4)
        else: raise RuntimeError('Stimulus not recognized')
        if (dist_code[1] == "1"): stim_arg[1]=1
        elif (dist_code[1] == "2"): stim_arg[1]=8
        elif (dist_code[1] == "3"): stim_arg[1]=6
        elif (dist_code[1] == "4"): stim_arg[1]=4
        else: raise RuntimeError('Stimulus not recognized')
        for i in range(NUM_DISTRACTORS + 1 - trial):
            conflicted = True
            while conflicted:
                x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                y = randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP)
                conflicted = False
                if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                    conflicted = True
                if not conflicted:
                    for j in trialComponents['distractors']:
                        if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                            conflicted = True
            trialComponents['distractors'].append(NewStimuli(stim_arg[0],stim_arg[1],stim_arg[2],stim_arg[3],x,y))
                    
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED
            else:
                if hasattr(value,'status'): value.status = NOT_STARTED
        dist_status = NOT_STARTED # create my own status variable to avoid ~20 checks every cycle
        
        #Save initial stimuli heights for movement
        initial = {'distractors':[]}
        for i in range(len(trialComponents['distractors'])):
            initial['distractors'].append(trialComponents['distractors'][i].pos[1])
        if trialComponents['target'] is not None:
            initial['target'] = trialComponents['target'].pos[1]
        
        
#------- READY SCREEN --------
        readyCue.setAutoDraw(True)
        win.flip()
        sleep(READY_TIME)
        readyCue.setAutoDraw(False)
        win.flip()
        
        # Ready the clocks
        t=0; trialClock.reset() #clock 
        frameN=-1
        routineTimer.reset()
        routineTimer.add(MAX_TIME)
        
        #-------Start Routine "trial"-------
        continueRoutine=True
        while continueRoutine and routineTimer.getTime()>0:
            #get current time
            t=trialClock.getTime()
            frameN=frameN+1#number of completed frames (so 0 in first frame)
            
            #*target* update
            if trialComponents['target'] is not None:
                if (t >= 0 and trialComponents['target'].status == NOT_STARTED):
                    trialComponents['target'].tStart=t
                    trialComponents['target'].frameNStart=frameN
                    trialComponents['target'].setAutoDraw(True)
                elif (trialComponents['target'].status == STARTED and t >= MAX_TIME):
                    trialComponents['target'].setAutoDraw(False)
                elif (trialComponents['target'].status == STARTED and expInfo['condition']=='d'):
                    if trialComponents['target'].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['target'] += DISPLAY_DIMENSIONS[1]
                        y = initial['target']-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            for j in trialComponents['distractors']:
                                if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                    conflicted = True
                        trialComponents['target'].setPos([x, y])
                    else:
                        trialComponents['target'].setPos([trialComponents['target'].pos[0], initial['target']-int(t*FALL_RATE)])
            #*dist* update
            if (t >= 0 and dist_status == NOT_STARTED):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(True)
                dist_status = STARTED
            elif (dist_status == STARTED and t >= MAX_TIME):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(False)
                dist_status = FINISHED
            elif (dist_status == STARTED and expInfo['condition']=='d'):
                for each in range(len(trialComponents['distractors'])):
                    if trialComponents['distractors'][each].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['distractors'][each] += DISPLAY_DIMENSIONS[1]
                        y =  initial['distractors'][each]-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                                conflicted = True
                            if not conflicted:
                                for j in trialComponents['distractors']:
                                    if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                        conflicted = True
                        trialComponents['distractors'][each].setPos([x, y])
                    else:
                        trialComponents['distractors'][each].setPos([trialComponents['distractors'][each].pos[0], initial['distractors'][each]-int(t*FALL_RATE)])
                            
            # Record starting positions of stimuli
            if expInfo['condition']=='d':
                stimLog[0].append(t)
                offset = 1
                if trialComponents['target'] is not None:
                    stimLog[1].append(trialComponents['target'].pos[0])
                    stimLog[2].append(trialComponents['target'].pos[1])
                    offset = 3
                for i in range(len(trialComponents['distractors'])):
                    stimLog[i+offset].append(trialComponents['distractors'][i].pos[0])
                    stimLog[i+offset+1].append(trialComponents['distractors'][i].pos[1])
                    offset += 1
                
                
            #*mouse* updates
            if t >= 0 and trialComponents['mouse'].status==NOT_STARTED:
                trialComponents['mouse'].clickReset()
                #keep track of start time/frame for later
                trialComponents['mouse'].tStart=t#underestimates by a little under one frame
                trialComponents['mouse'].frameNStart=frameN#exact frame index
                trialComponents['mouse'].status=STARTED
                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if expInfo['response style'] == 'd':
                    #trialComponents['mouse'].setPos(0,0)
                    autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
                    trialComponents['mouse'].setVisible(True)
            elif trialComponents['mouse'].status==STARTED and t >= MAX_TIME:
                trialComponents['mouse'].status=STOPPED
                if expInfo['response style'] == 'd':
                    trialComponents['mouse'].setVisible(False)
            if trialComponents['mouse'].status==STARTED and sum(response)==0: #only update if started and no previous response has been recorded
                buttons, times = trialComponents['mouse'].getPressed(getTime=True)
                if sum(buttons) == 1:
                    if buttons[0] == 1:
                        if expInfo['response style'] == 'd':
                        
                            #Check if on stimuli
                            on_stim = False
                            if trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                on_stim = True
                            else:
                                for shape in trialComponents['distractors']:
                                    if shape.contains(trialComponents['mouse'].getPos()):
                                        clickLoc = trialComponents['mouse'].getPos()
                                        on_stim = True
                                        break
                            if on_stim:
                                response = [1,0]
                                rt = times[0]
                                clickLoc = trialComponents['mouse'].getPos()
                                trialComponents['mouse'].setVisible(False)
                                continueRoutine = False
                            else: #continue with the trial until they click on something meaningful
                                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                        else: # Target Present Response in Static Stimuli
                            response = [1,0]
                            rt = times[0]
                            continueRoutine = False
                    elif buttons[2] == 1: # Target Absent Response
                        response = [0,1]
                        rt = times[2]
                        continueRoutine = False
                    else: # mouse wheel was pressed
                        event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if sum(buttons) > 0: #Either wheel was pressed or more than one button was pressed. Reset the mouse and continue with the trial.
                    event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            
            #check if all components have finished
            if not continueRoutine: #a component has requested that we end
                routineTimer.reset() #this is the new t0 for non-slip Routines
                break
            continueRoutine=False#will revert to True if at least one component still running
            for key, value in trialComponents.iteritems():
                if key == 'distractors':
                    for thisComponent in value:
                        if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
                else:
                    if hasattr(value,"status") and value.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
            
            #check for quit (the [Esc] key)
            if event.getKeys(["escape"]):
                core.quit()
            
            #refresh the screen
            if continueRoutine:
                win.flip()
                
        #Stop drawing the stimuli
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'setAutoDraw'): thisComponent.setAutoDraw(False)
            else:
                if hasattr(value,'setAutoDraw'): value.setAutoDraw(False)
        
        # FINISH UP RESPONSE FOR STATIC RESPONSE STYLE
        if expInfo['response style'] == 's' and response[0] == 1:
            event.mouseButtons = [0,0,0]
            win.flip() # Go to blank screen
            if trialComponents['target'] is not None:
                targetDecoy = NewStimuli(win, 3, STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1], orientation=180)
                targetDecoy.setLineColor((0,0,0))
                targetDecoy.setAutoDraw(True)
            distDecoys = []
            for each in trialComponents['distractors']:
                distDecoys.append(NewStimuli(win, 3, STIM_RAD, (255,255,255), each.pos[0], each.pos[1], orientation=180))
                distDecoys[-1].setLineColor((0,0,0))
                distDecoys[-1].setAutoDraw(True)
            autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
            trialComponents['mouse'].setVisible(True)
            get_response = True
            while get_response:
                win.flip()
                #check for quit (the [Esc] key)
                if event.getKeys(["escape"]):
                    core.quit()
                #check for response
                if trialComponents['mouse'].getPressed()[0] != 0:
                    #check for click ON STIMULI
                    if trialComponents['target'] is not None and targetDecoy.contains(trialComponents['mouse'].getPos()):
                        clickLoc = trialComponents['mouse'].getPos()
                        get_response = False
                    else:
                        for shape in distDecoys:
                            if shape.contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                get_response = False
                                break
                else:
                    event.mouseButtons=[0,0,0]
            trialComponents['mouse'].setVisible(False)
            if trialComponents['target'] is not None:
                targetDecoy.setAutoDraw(False)
            for each in distDecoys:
                each.setAutoDraw(False)
        else:
            win.flip()
            sleep(1.00)
        #End of Routine "trial"
        
        # PROVIDE FEEDBACK
        # If they were correct just give em a pat on the back
        if trial == 0 and response[1] == 1:
            feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
            feedback.setAutoDraw(True)
            event.mouseButtons=[0,0,0]
            while trialComponents['mouse'].getPressed()[0] == 0:
                win.flip()
            trialComponents['mouse'].clickReset()
            feedback.setAutoDraw(False)
            win.flip()
        else:
            try:
                targetDecoy
                if trial == 1 and response[0] == 1 and targetDecoy.contains(clickLoc):
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    win.flip()
                else:
                    raise NameError
            except NameError:
                # If they were wrong show them the original stimuli
                #if expInfo['response style'] == 's' and response[0] == 1:
                #    if trialComponents['target'] is not None:
                #        targetDecoy.setAutoDraw(False)
                #    for shape in distDecoys:
                #        shape.setAutoDraw(False)
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(True)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(True)
                    
                if trial == 0:
                    # Wrong - there is no target
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. There is no target on this trial.',
                        units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    #win.flip()
                else:
                    # Wrong - the target is here
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                            units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #if trialComponents['target'].pos[1] > 0:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]-400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #else:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]+400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    focus = NewStimuli(win, 1, 2*STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1])
                    focus.setLineColor((0,0,0))
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        feedback.draw(win)
                        focus.draw(win)
                        trialComponents['target'].draw(win) # Anticipating needing this
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    focus.setAutoDraw(False)
                    #win.flip()
                
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(False)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(False)
                win.flip()
                
    #### End of practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    endOfPracticeWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    endOfPracticeWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]

def ShapeCapInstructions ():

    sColInstructions = visual.TextStim(win=win, ori=0, name='SCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of red shapes. Examples are below:\n\n\nOne of the objects may be different from the others in its shape.\n\nIf there is a different object present, click the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button.\n\nIf you responded that there was a different object present, you will be asked to click with the LEFT mouse button where you found it.\n\nIf you responded that all the objects were the same, the trial will progress normally.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix", height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    dColInstructions = visual.TextStim(win=win, ori=0, name='DCinstructions',
        text='After the words "Get Ready..." are displayed, you will see a field of red shapes.\nExamples are below:\n\n\nOne of the objects may be different from the others in its shape.\n\nIf there is a different object present, click on it with the LEFT mouse button.\n\nIf all the objects are the same, click the RIGHT mouse button anywhere.\n\nClick the mouse when you are ready to begin...',
        font='Arial', pos=[0, 0], units="pix",height=40,wrapWidth=DISPLAY_DIMENSIONS[0]-100,
        color='black', colorSpace='rgb', opacity=1, depth=0.0)
    exampleStim = [NewStimuli(win, 1, STIM_RAD, _COLOR1, -500, 250, orientation=22.5), NewStimuli(win, 8, STIM_RAD, _COLOR1, -500+1*3*STIM_RAD, 250, orientation=22.5),
        NewStimuli(win, 6, STIM_RAD, _COLOR1, -500+2*3*STIM_RAD, 250, orientation=22.5), NewStimuli(win, 4, STIM_RAD, _COLOR1, -500+3*3*STIM_RAD, 250, orientation=22.5)]
    
#------Prepare to start Routine"Instructions"-------
    t=0; instructionsClock.reset() #clock 
    frameN=-1
    InstructionsComponents={}
    if (expInfo['response style']=='s'):
        InstructionsComponents['instructions']=(sColInstructions)
    elif (expInfo['response style']=='d'):
        InstructionsComponents['instructions']=(dColInstructions)
    else:
        raise RuntimeError('Failed to Initialise Instructions')
    InstructionsComponents['mouse']=(mouse)
    for key,thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED

    #-------Start Routine "Instructions"-------
    continueRoutine=True
    while continueRoutine:
        #get current time
        t=instructionsClock.getTime()
        frameN=frameN+1#number of completed frames (so 0 in first frame)
        #update/draw components on each frame
        
        #*text* updates
        if t>=0.0 and InstructionsComponents['instructions'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['instructions'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['instructions'].frameNStart=frameN#exact frame index
            InstructionsComponents['instructions'].setAutoDraw(True)
            for s in exampleStim:
                s.setAutoDraw(True)
        #*mouse* updates
        if t>=0.0 and InstructionsComponents['mouse'].status==NOT_STARTED:
            #keep track of start time/frame for later
            InstructionsComponents['mouse'].tStart=t#underestimates by a little under one frame
            InstructionsComponents['mouse'].frameNStart=frameN#exact frame index
            InstructionsComponents['mouse'].status=STARTED
            event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
        if InstructionsComponents['mouse'].status==STARTED:#only update if started and not stopped!
            buttons = mouse.getPressed()
            if sum(buttons)>0:#ie if any button is pressed
                #abort routine on response
                continueRoutine=False
        
        #check if all components have finished
        if not continueRoutine: #a component has requested that we end
            routineTimer.reset() #this is the new t0 for non-slip Routines
            break
        continueRoutine=False#will revert to True if at least one component still running
        for key, thisComponent in InstructionsComponents.iteritems():
            if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                continueRoutine=True; break#at least one component has not yet finished
        
        #check for quit (the [Esc] key)
        if event.getKeys(["escape"]):
            core.quit()
        
        #refresh the screen
        if continueRoutine:#don't flip if this routine is over or we'll get a blank screen
            win.flip()

    #End of Routine "Instructions"
    for key, thisComponent in InstructionsComponents.iteritems():
        if hasattr(thisComponent,"setAutoDraw"): thisComponent.setAutoDraw(False)
        for s in exampleStim:
            s.setAutoDraw(False)
    #Blank the Instructions Screen
    win.flip()
    
    #### Practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    sixteenTrialWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    sixteenTrialWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    
    #### Begin Dynamic Instructions ####
    possStimuli = ("1_1", "1_2", "1_3", "1_4")
    instrConds = [0,1] * 4 # use this to specify target presence
    targetOrder = range(len(possStimuli))
    #instrConds = ["RC23VD","RC23VO","RC23VC","RC23MD","RC23MO","RC23MC","RC23RD","RC23RO","AB24VD","AB24VO","AB24VC","AB24MD","AB24MO","AB24MC","AB24RD","AB24RO"]
    shuffle(instrConds); shuffle(targetOrder)
    
    for trial in instrConds:
    
        response = [0,0]
        rt = -1
        clickLoc = [None,None]
        
        trialComponents = {'mouse':mouse, 'distractors':[]}
        #load stimuli
        if trial == 1: # Target Present
            targetType = targetOrder.pop()
            distType = choice([x for i,x in enumerate(range(len(possStimuli))) if i!=targetType])
            target_code = possStimuli[targetType].split('_')
            stim_arg = [win,1,STIM_RAD] 
            if (target_code[0] == "1"): stim_arg.append(_COLOR1)
            elif (target_code[0] == "2"): stim_arg.append(_COLOR2)
            elif (target_code[0] == "3"): stim_arg.append(_COLOR3)
            elif (target_code[0] == "4"): stim_arg.append(_COLOR4)
            else: raise RuntimeError('Stimulus not recognized')
            if (target_code[1] == "1"): stim_arg[1]=1
            elif (target_code[1] == "2"): stim_arg[1]=8
            elif (target_code[1] == "3"): stim_arg[1]=6
            elif (target_code[1] == "4"): stim_arg[1]=4
            else: raise RuntimeError('Stimulus not recognized')
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP))
            stim_arg.append(randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP))
            trialComponents['target'] = NewStimuli(*stim_arg)
        else: # Target Absent
            trialComponents['target'] = None
            distType = randint(len(possStimuli))
        
        
        dist_code = possStimuli[distType].split('_')
        stim_arg = [win,1,STIM_RAD] 
        if (dist_code[0] == "1"): stim_arg.append(_COLOR1)
        elif (dist_code[0] == "2"): stim_arg.append(_COLOR2)
        elif (dist_code[0] == "3"): stim_arg.append(_COLOR3)
        elif (dist_code[0] == "4"): stim_arg.append(_COLOR4)
        else: raise RuntimeError('Stimulus not recognized')
        if (dist_code[1] == "1"): stim_arg[1]=1
        elif (dist_code[1] == "2"): stim_arg[1]=8
        elif (dist_code[1] == "3"): stim_arg[1]=6
        elif (dist_code[1] == "4"): stim_arg[1]=4
        else: raise RuntimeError('Stimulus not recognized')
        for i in range(NUM_DISTRACTORS + 1 - trial):
            conflicted = True
            while conflicted:
                x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                y = randint(-.5*DISPLAY_DIMENSIONS[1]+MIN_SEP,.5*DISPLAY_DIMENSIONS[1]-MIN_SEP)
                conflicted = False
                if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                    conflicted = True
                if not conflicted:
                    for j in trialComponents['distractors']:
                        if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                            conflicted = True
            trialComponents['distractors'].append(NewStimuli(stim_arg[0],stim_arg[1],stim_arg[2],stim_arg[3],x,y))
                    
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'status'): thisComponent.status = NOT_STARTED
            else:
                if hasattr(value,'status'): value.status = NOT_STARTED
        dist_status = NOT_STARTED # create my own status variable to avoid ~20 checks every cycle
        
        #Save initial stimuli heights for movement
        initial = {'distractors':[]}
        for i in range(len(trialComponents['distractors'])):
            initial['distractors'].append(trialComponents['distractors'][i].pos[1])
        if trialComponents['target'] is not None:
            initial['target'] = trialComponents['target'].pos[1]
        
        
#------- READY SCREEN --------
        readyCue.setAutoDraw(True)
        win.flip()
        sleep(READY_TIME)
        readyCue.setAutoDraw(False)
        win.flip()
        
        # Ready the clocks
        t=0; trialClock.reset() #clock 
        frameN=-1
        routineTimer.reset()
        routineTimer.add(MAX_TIME)
        
        #-------Start Routine "trial"-------
        continueRoutine=True
        while continueRoutine and routineTimer.getTime()>0:
            #get current time
            t=trialClock.getTime()
            frameN=frameN+1#number of completed frames (so 0 in first frame)
            
            #*target* update
            if trialComponents['target'] is not None:
                if (t >= 0 and trialComponents['target'].status == NOT_STARTED):
                    trialComponents['target'].tStart=t
                    trialComponents['target'].frameNStart=frameN
                    trialComponents['target'].setAutoDraw(True)
                elif (trialComponents['target'].status == STARTED and t >= MAX_TIME):
                    trialComponents['target'].setAutoDraw(False)
                elif (trialComponents['target'].status == STARTED and expInfo['condition']=='d'):
                    if trialComponents['target'].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['target'] += DISPLAY_DIMENSIONS[1]
                        y = initial['target']-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            for j in trialComponents['distractors']:
                                if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                    conflicted = True
                        trialComponents['target'].setPos([x, y])
                    else:
                        trialComponents['target'].setPos([trialComponents['target'].pos[0], initial['target']-int(t*FALL_RATE)])
            #*dist* update
            if (t >= 0 and dist_status == NOT_STARTED):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(True)
                dist_status = STARTED
            elif (dist_status == STARTED and t >= MAX_TIME):
                for this in trialComponents['distractors']:
                    this.setAutoDraw(False)
                dist_status = FINISHED
            elif (dist_status == STARTED and expInfo['condition']=='d'):
                for each in range(len(trialComponents['distractors'])):
                    if trialComponents['distractors'][each].pos[1] <= -.5*DISPLAY_DIMENSIONS[1]:
                        initial['distractors'][each] += DISPLAY_DIMENSIONS[1]
                        y =  initial['distractors'][each]-int(t*FALL_RATE)
                        conflicted = True
                        while conflicted:
                            x = randint(-.5*DISPLAY_DIMENSIONS[0]+MIN_SEP,.5*DISPLAY_DIMENSIONS[0]-MIN_SEP)
                            conflicted = False
                            if (trialComponents['target'] is not None and x < trialComponents['target'].pos[0]+MIN_SEP and x > trialComponents['target'].pos[0]-MIN_SEP and y < trialComponents['target'].pos[1]+MIN_SEP and y > trialComponents['target'].pos[1]-MIN_SEP):
                                conflicted = True
                            if not conflicted:
                                for j in trialComponents['distractors']:
                                    if (x < j.pos[0]+MIN_SEP and x > j.pos[0]-MIN_SEP and y < j.pos[1]+MIN_SEP and y > j.pos[1]-MIN_SEP):
                                        conflicted = True
                        trialComponents['distractors'][each].setPos([x, y])
                    else:
                        trialComponents['distractors'][each].setPos([trialComponents['distractors'][each].pos[0], initial['distractors'][each]-int(t*FALL_RATE)])
                            
            # Record starting positions of stimuli
            if expInfo['condition']=='d':
                stimLog[0].append(t)
                offset = 1
                if trialComponents['target'] is not None:
                    stimLog[1].append(trialComponents['target'].pos[0])
                    stimLog[2].append(trialComponents['target'].pos[1])
                    offset = 3
                for i in range(len(trialComponents['distractors'])):
                    stimLog[i+offset].append(trialComponents['distractors'][i].pos[0])
                    stimLog[i+offset+1].append(trialComponents['distractors'][i].pos[1])
                    offset += 1
                
                
            #*mouse* updates
            if t >= 0 and trialComponents['mouse'].status==NOT_STARTED:
                trialComponents['mouse'].clickReset()
                #keep track of start time/frame for later
                trialComponents['mouse'].tStart=t#underestimates by a little under one frame
                trialComponents['mouse'].frameNStart=frameN#exact frame index
                trialComponents['mouse'].status=STARTED
                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if expInfo['response style'] == 'd':
                    #trialComponents['mouse'].setPos(0,0)
                    autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
                    trialComponents['mouse'].setVisible(True)
            elif trialComponents['mouse'].status==STARTED and t >= MAX_TIME:
                trialComponents['mouse'].status=STOPPED
                if expInfo['response style'] == 'd':
                    trialComponents['mouse'].setVisible(False)
            if trialComponents['mouse'].status==STARTED and sum(response)==0: #only update if started and no previous response has been recorded
                buttons, times = trialComponents['mouse'].getPressed(getTime=True)
                if sum(buttons) == 1:
                    if buttons[0] == 1:
                        if expInfo['response style'] == 'd':
                        
                            #Check if on stimuli
                            on_stim = False
                            if trialComponents['target'].contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                on_stim = True
                            else:
                                for shape in trialComponents['distractors']:
                                    if shape.contains(trialComponents['mouse'].getPos()):
                                        clickLoc = trialComponents['mouse'].getPos()
                                        on_stim = True
                                        break
                            if on_stim:
                                response = [1,0]
                                rt = times[0]
                                clickLoc = trialComponents['mouse'].getPos()
                                trialComponents['mouse'].setVisible(False)
                                continueRoutine = False
                            else: #continue with the trial until they click on something meaningful
                                event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                        else: # Target Present Response in Static Stimuli
                            response = [1,0]
                            rt = times[0]
                            continueRoutine = False
                    elif buttons[2] == 1: # Target Absent Response
                        response = [0,1]
                        rt = times[2]
                        continueRoutine = False
                    else: # mouse wheel was pressed
                        event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
                if sum(buttons) > 0: #Either wheel was pressed or more than one button was pressed. Reset the mouse and continue with the trial.
                    event.mouseButtons=[0,0,0] #reset mouse buttons to be 'up'
            
            #check if all components have finished
            if not continueRoutine: #a component has requested that we end
                routineTimer.reset() #this is the new t0 for non-slip Routines
                break
            continueRoutine=False#will revert to True if at least one component still running
            for key, value in trialComponents.iteritems():
                if key == 'distractors':
                    for thisComponent in value:
                        if hasattr(thisComponent,"status") and thisComponent.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
                else:
                    if hasattr(value,"status") and value.status!=FINISHED:
                            continueRoutine=True; break#at least one component has not yet finished
            
            #check for quit (the [Esc] key)
            if event.getKeys(["escape"]):
                core.quit()
            
            #refresh the screen
            if continueRoutine:
                win.flip()
                
        #Stop drawing the stimuli
        for key, value in trialComponents.iteritems():
            if key == 'distractors':
                for thisComponent in value:
                    if hasattr(thisComponent,'setAutoDraw'): thisComponent.setAutoDraw(False)
            else:
                if hasattr(value,'setAutoDraw'): value.setAutoDraw(False)
        
        # FINISH UP RESPONSE FOR STATIC RESPONSE STYLE
        if expInfo['response style'] == 's' and response[0] == 1:
            event.mouseButtons = [0,0,0]
            win.flip() # Go to blank screen
            if trialComponents['target'] is not None:
                targetDecoy = NewStimuli(win, 3, STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1], orientation=180)
                targetDecoy.setLineColor((0,0,0))
                targetDecoy.setAutoDraw(True)
            distDecoys = []
            for each in trialComponents['distractors']:
                distDecoys.append(NewStimuli(win, 3, STIM_RAD, (255,255,255), each.pos[0], each.pos[1], orientation=180))
                distDecoys[-1].setLineColor((0,0,0))
                distDecoys[-1].setAutoDraw(True)
            autopy.mouse.move(int(.5*DISPLAY_DIMENSIONS[0]), int(.5*DISPLAY_DIMENSIONS[1]))
            trialComponents['mouse'].setVisible(True)
            get_response = True
            while get_response:
                win.flip()
                #check for quit (the [Esc] key)
                if event.getKeys(["escape"]):
                    core.quit()
                #check for response
                if trialComponents['mouse'].getPressed()[0] != 0:
                    #check for click ON STIMULI
                    if trialComponents['target'] is not None and targetDecoy.contains(trialComponents['mouse'].getPos()):
                        clickLoc = trialComponents['mouse'].getPos()
                        get_response = False
                    else:
                        for shape in distDecoys:
                            if shape.contains(trialComponents['mouse'].getPos()):
                                clickLoc = trialComponents['mouse'].getPos()
                                get_response = False
                                break
                else:
                    event.mouseButtons=[0,0,0]
            trialComponents['mouse'].setVisible(False)
            if trialComponents['target'] is not None:
                targetDecoy.setAutoDraw(False)
            for each in distDecoys:
                each.setAutoDraw(False)
        else:
            win.flip()
            sleep(1.00)
        #End of Routine "trial"
        
        # PROVIDE FEEDBACK
        # If they were correct just give em a pat on the back
        if trial == 0 and response[1] == 1:
            feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
            feedback.setAutoDraw(True)
            event.mouseButtons=[0,0,0]
            while trialComponents['mouse'].getPressed()[0] == 0:
                win.flip()
            trialComponents['mouse'].clickReset()
            feedback.setAutoDraw(False)
            win.flip()
        else:
            try:
                targetDecoy
                if trial == 1 and response[0] == 1 and targetDecoy.contains(clickLoc):
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Correct!', units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    win.flip()
                else:
                    raise NameError
            except NameError:
                # If they were wrong show them the original stimuli
                #if expInfo['response style'] == 's' and response[0] == 1:
                #    if trialComponents['target'] is not None:
                #        targetDecoy.setAutoDraw(False)
                #    for shape in distDecoys:
                #        shape.setAutoDraw(False)
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(True)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(True)
                    
                if trial == 0:
                    # Wrong - there is no target
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. There is no target on this trial.',
                        units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    #win.flip()
                else:
                    # Wrong - the target is here
                    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                            units="norm", font='Arial', pos=[0, 0], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #if trialComponents['target'].pos[1] > 0:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]-400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    #else:
                    #    feedback = visual.TextStim(win=win, ori=0, name='pos_feedback', text='Incorrect. The target is here.',
                    #        units="norm", font='Arial', pos=[0, trialComponents['target'].pos[1]+400], height=0.1, wrapWidth=None, color='black', colorSpace='rgb', opacity=1, depth=0.0)
                    feedback.setAutoDraw(True)
                    focus = NewStimuli(win, 1, 2*STIM_RAD, (255,255,255), trialComponents['target'].pos[0], trialComponents['target'].pos[1])
                    focus.setLineColor((0,0,0))
                    event.mouseButtons=[0,0,0]
                    while trialComponents['mouse'].getPressed()[0] == 0:
                        feedback.draw(win)
                        focus.draw(win)
                        trialComponents['target'].draw(win) # Anticipating needing this
                        win.flip()
                    trialComponents['mouse'].clickReset()
                    feedback.setAutoDraw(False)
                    focus.setAutoDraw(False)
                    #win.flip()
                
                if trialComponents['target'] is not None:
                    trialComponents['target'].setAutoDraw(False)
                for each in trialComponents['distractors']:
                    each.setAutoDraw(False)
                win.flip()
                
    #### End of practice trials warnings screen ####
    event.mouseButtons = [0,0,0]
    endOfPracticeWarning.setAutoDraw(True)
    win.flip()
    while mouse.getPressed()[0] != 1:
        pass
    endOfPracticeWarning.setAutoDraw(False)
    win.flip()
    event.mouseButtons = [0,0,0]
    


#ConjSearchInstructions()
#if expInfo['session'] == '1':
if random() < .5:
    ColorCapInstructions()
    VisualSearch(CAP_BLOCKS, 'VSwSFT 3 Cap Color Conditions.csv')
    ShapeCapInstructions()
    VisualSearch(CAP_BLOCKS, 'VSwSFT 3 Cap Shape Conditions.csv')
else:
    ShapeCapInstructions()
    VisualSearch(CAP_BLOCKS, 'VSwSFT 3 Cap Shape Conditions.csv')
    ColorCapInstructions()
    VisualSearch(CAP_BLOCKS, 'VSwSFT 3 Cap Color Conditions.csv')
        
SingletonSearchInstructions()
VisualSearch(NUM_BLOCKS, 'VSwSFT 3 Conditions.csv')
  
logFile.close()
stimFile.close()

# Tell them to go fetch the experimenter
mouse.clickReset()
while not event.getKeys(["space"]):
    outcome_message.setAutoDraw(True)
    win.flip()
outcome_message.setAutoDraw(False)
win.flip()

win.close()
core.quit()
