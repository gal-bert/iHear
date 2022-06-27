//
//  TranscriptionViewController.swift
//  NYHM
//
//  Created by Hafizh Mo on 12/06/22.
//

import UIKit
import Speech
import AVKit

protocol SaveTranscriptionProtocol {
    func reloadTableView()
}

class TranscriptionViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationLabelBottom: UILabel!
    @IBOutlet weak var transcriptionResultTextView: UITextView!
    @IBOutlet weak var transcribeActionButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var textViewToTitleConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewToButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var navbar: UINavigationBar!
    
    @IBOutlet weak var titleToSuperview: NSLayoutConstraint!
    @IBOutlet weak var durationToSuperView: NSLayoutConstraint!
    
    @IBOutlet weak var textViewToDurationConstraint: NSLayoutConstraint!
    
    var delegate:SaveTranscriptionProtocol?
    
    var transcriptionTemp = ""
    var transcriptionTemp2 = ""
    var filename:URL?
    var filenameToSave:String = ""
    var isPlaying:Bool = true
    
    var durationString:String = ""
    
    let audioEngine = AVAudioEngine()
    
    var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?
    
    var timer: Timer?
    var durationTemp:Int = 0
    
    var numberOfChannelForAudio = 2
    
    let updateInterval = 0.00005
    var waveTimer: Timer?
    
    var waveView = WaveView()
    
    var sineWaveView = UIView()
//    @IBOutlet weak var sinewaveView: UIView!
    
    let isWaveformVisible = UserDefaults.standard.bool(forKey: Constants.IS_WAVEFORM_VISIBLE)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechRecognizer?.delegate = self
        audioRecorder?.delegate = self
        
        transcriptionResultTextView.text = ""
        
        initSpeechAuth()
        initRecordingSession()
        initDuration()
        
        transcribeOnLoad()
        startRecording()
        
//        sineWaveView = waveView.theView
//        sineWaveView.tag = 378
        turnTheWave(bool: isWaveformVisible)
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        waveTimer?.invalidate()
        waveView.timer.invalidate()
        turnTheWave(bool: false)
        delegate?.reloadTableView()
    }
    
    func initDuration() -> Void {
        
        durationLabel.text = "00:00:00"
        durationLabelBottom.text = "00:00:00"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.isPlaying {
                self.durationTemp += 1
                
                self.durationTemp.hmsFrom(seconds: self.durationTemp) { hours, minutes, seconds in
                    let hours = seconds.getStringFrom(seconds: hours)
                    let minutes = seconds.getStringFrom(seconds: minutes)
                    let seconds = seconds.getStringFrom(seconds: seconds)
                    self.durationLabel.text = "\(hours):\(minutes):\(seconds)"
                    self.durationLabelBottom.text = "\(hours):\(minutes):\(seconds)"
                }
                
                
            }
        }
    }
    
    
    
    func initSpeechAuth() -> Void {
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var msg = ""
            
            switch authStatus {
            case .notDetermined:
                msg = "Transcribe Ready"
            case .denied:
                msg = "Speech Recognition Permission Denied"
            case .restricted:
                msg = "Speech Recognition Restricted"
            case .authorized:
                msg = "Speech Recognition Restricted"
            @unknown default:
                fatalError()
            }
            print(msg)
            
        }
    }
    
    func initRecordingSession() -> Void {
        recordingSession = AVAudioSession.sharedInstance()
        do{
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission({ [unowned self] allowed in
                
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording instance ok")
                    } else {
                        print("Recording instance failed")
                    }
                }
                
            })
        } catch {
            print("Recording Session Error")
            print(error.localizedDescription)
        }
        
        setupNotifications()
    }
    
    func startRecording() -> Void {
        filename = getFileUrl()
        
        do {
            audioRecorder = try AVAudioRecorder(
                url: filename!,
                settings: [
                    AVFormatIDKey: kAudioFormatAppleLossless,
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: numberOfChannelForAudio,
                    AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
                ]
            )
            audioRecorder?.record()
            
            audioRecorder!.isMeteringEnabled = true
            if isWaveformVisible {
                startWave()
            }
            
        } catch {
            if isWaveformVisible {
                waveTimer?.invalidate()
                waveView.timer.invalidate()
            }
            audioRecorder!.isMeteringEnabled = false
            stopRecording()
        }
        
    }
    
    func continueRecording() -> Void {
        audioRecorder?.isMeteringEnabled = true
        if isWaveformVisible {
            startWave()
        }
        audioRecorder?.record()
    }
    
    func pauseRecording() -> Void {
        audioRecorder!.isMeteringEnabled = false
        if isWaveformVisible {
            waveTimer?.invalidate()
        }
        audioRecorder?.pause()
    }
    
    func stopRecording() -> Void {
        audioRecorder!.isMeteringEnabled = false
        if isWaveformVisible {
            waveTimer?.invalidate()
            waveView.timer.invalidate()
        }
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            if isWaveformVisible {
                waveTimer?.invalidate()
                waveView.timer.invalidate()
            }
            audioRecorder!.isMeteringEnabled = false
            stopRecording()
        }
    }
    
    func getFileUrl() -> URL {
        let date = Date()
        filenameToSave = "\(date.generateTimestampForFilename()).m4a"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filenameToSave)
    }
    
    func startTranscription() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Speech Request Error")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if result != nil {
                
                isFinal = (result?.isFinal)!
                
                self.transcriptionTemp2 = (result?.bestTranscription.formattedString)!
                
                var concat = ""
                
                if self.isPlaying{
                    let range = NSMakeRange(self.transcriptionResultTextView.text.count - 1, 0)
                    self.transcriptionResultTextView.scrollRangeToVisible(range)
                    
                    if self.transcriptionTemp == "" {
                        concat = "\(self.transcriptionTemp)\(self.transcriptionTemp2)"
                    } else {
                        concat = "\(self.transcriptionTemp)\n\n\(self.transcriptionTemp2)"
                    }
                    
                    self.transcriptionResultTextView.text = concat
                    print(concat)
                    
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        self.audioEngine.prepare()
        
        do {
            try self.audioEngine.start()
        } catch {
            print("Audio Engine start error \n \(error.localizedDescription)")
        }
        
    }
    
    func transcribeOnLoad() -> Void {
        
        // State is playing, command to stop
        if audioEngine.isRunning {
            if transcriptionTemp == "" {
                transcriptionTemp += "\(transcriptionTemp2)"
            } else {
                transcriptionTemp += "\n\n\(transcriptionTemp2)"
            }
            transcriptionResultTextView.text = transcriptionTemp
            transcriptionTemp2 = ""
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
            pauseRecording()
            
            transcribeActionButton.setTitle("", for: .normal)
            transcribeActionButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            saveButton.isEnabled = true
            isPlaying = false
        }
        
        // State is stopped, command to start
        else {
            let locale = UserDefaults.standard.string(forKey: Constants.SELECTED_LANGUAGE)
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale!))
            startTranscription()
            continueRecording()
            
            transcribeActionButton.setTitle("", for: .normal)
            transcribeActionButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            saveButton.isEnabled = false
            isPlaying = true
            
            
            
        }
        let fourthBg = UIColor(named: "fourthBg")
        
        self.titleTextField.backgroundColor = fourthBg
       
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }
    
    func removeInterruptionObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            let reason = AVAudioSession.InterruptionReason(rawValue: typeValue) else {
                return
        }

        switch type {
            case .began:
                switch reason {
                    case .appWasSuspended:
                    if isPlaying == true {
                        transcriptionTemp = transcriptionResultTextView.text
                        saveTranscription()
                    }
                    default: ()
                }
            default: ()
        }
    }
    
    func stateDidChange(newState: Int) {
        
        switch newState {
            
        case 1: // full modal
            navbar.isHidden = false
            titleToSuperview.constant = 60
            durationLabel.isHidden = true
            textViewToTitleConstraint.constant = 20
            textViewToButtonConstraint.constant = 60
            
            textViewToDurationConstraint.constant = 20
            
            durationLabelBottom.isHidden = false
            titleTextField.isHidden = false
            durationToSuperView.constant = 100
            
            if isWaveformVisible {
                textViewToButtonConstraint.constant = 160
                textViewToDurationConstraint.constant = 120
                audioRecorder!.isMeteringEnabled = true
                turnTheWave(bool: true)
            } else {
                audioRecorder!.isMeteringEnabled = false
                turnTheWave(bool: false)
            }
            
        case 2: // half modal
            
            navbar.isHidden = true
            titleToSuperview.constant = 20
            durationLabel.isHidden = false
            textViewToTitleConstraint.constant = 40
            textViewToButtonConstraint.constant = 400
            durationLabelBottom.isHidden = true
            titleTextField.isHidden = true
            durationToSuperView.constant = 20
            
            audioRecorder!.isMeteringEnabled = false
            turnTheWave(bool: false)
            
        default:
            print("default")
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
                
        let alert = UIAlertController(title: "Cancel Transcription?", message: "Are you sure to cancel the current transcription session?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: "Yes, Cancel",
            style: .destructive,
            handler: { _ in
                self.audioEngine.stop()
                self.dismiss(animated: true)
                self.removeInterruptionObserver()
            }
        ))

        alert.addAction(UIAlertAction(
            title: "Stay Transcribing",
            style: .cancel,
            handler: nil
        ))

        present(alert, animated: true)
        
    }
    
    @IBAction func save(_ sender: Any) {
        saveTranscription()
    }
    
    func saveTranscription() {
        audioRecorder!.isMeteringEnabled = false
        if isWaveformVisible {
            waveTimer?.invalidate()
            waveView.timer.invalidate()
            turnTheWave(bool: false)
        }
        audioEngine.stop()
        stopRecording()
        
        print(filename!)
        
        let strTitle = titleTextField.text == "" ? "Untitled Transcription" : titleTextField.text
        
        let audioAsset = AVURLAsset.init(url: filename!)
        let duration = Int(CMTimeGetSeconds(audioAsset.duration))
        
        durationTemp.hmsFrom(seconds: durationTemp) { hours, minutes, seconds in
            let hours = seconds.getStringFrom(seconds: hours)
            let minutes = seconds.getStringFrom(seconds: minutes)
            let seconds = seconds.getStringFrom(seconds: seconds)
            self.durationString = "\(hours):\(minutes):\(seconds)"
        }
        
        TranscriptionRepository.shared.add(
            title: strTitle!,
            result: transcriptionTemp,
            duration: durationString,
            filename: filenameToSave
        )
        
        removeInterruptionObserver()
        print("\(filenameToSave)")
        
        delegate?.reloadTableView()
        dismiss(animated: true)
        
    
        
        
    }
    
    
    @IBAction func transcriptionActionButton(_ sender: Any) {
        transcribeOnLoad()
    }
    
    
}

