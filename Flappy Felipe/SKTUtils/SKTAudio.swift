/*
 * Copyright (c) 2013-2014 Razeware LLC
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import AVFoundation

/**
 * Audio player that uses AVFoundation to play looping background music and
 * short sound effects. For when using SKActions just isn't good enough.
 */
open class SKTAudio {
  open var backgroundMusicPlayer: AVAudioPlayer?
  open var soundEffectPlayer: AVAudioPlayer?

  open class func sharedInstance() -> SKTAudio {
    return SKTAudioInstance
  }

  open func playBackgroundMusic(_ filename: String) {
    let url = Bundle.main.url(forResource: filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }
    do {
        backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url!)
        if backgroundMusicPlayer != nil{
            let player = backgroundMusicPlayer
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()
        }
    }catch {
        // couldn't load file :(
    }
  }

  open func pauseBackgroundMusic() {
    if let player = backgroundMusicPlayer {
      if player.isPlaying {
        player.pause()
      }
    }
  }

  open func resumeBackgroundMusic() {
    if let player = backgroundMusicPlayer {
      if !player.isPlaying {
        player.play()
      }
    }
  }

  open func playSoundEffect(_ filename: String) {
    let url = Bundle.main.url(forResource: filename, withExtension: nil)
    if (url == nil) {
      print("Could not find file: \(filename)")
      return
    }
    do{
        soundEffectPlayer = try AVAudioPlayer(contentsOf: url!)
        if let player = soundEffectPlayer {
            player.numberOfLoops = 0
            player.prepareToPlay()
            player.play()
        }
    } catch{
        print("error")
    }
  }
}

private let SKTAudioInstance = SKTAudio()
