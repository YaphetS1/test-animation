//
//  ViewController.swift
//  picnic
//
//  Created by Дмитрий Маринин on 17.10.2020.
//

import UIKit
import RxSwift
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var bug: UIImageView!
    
    @IBOutlet weak var fabricTop: UIImageView!
    @IBOutlet weak var fabricBottom: UIImageView!
    
    @IBOutlet weak var basketTop: UIImageView!
    @IBOutlet weak var basketBottom: UIImageView!
    
    @IBOutlet weak var basketTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var basketBottomConstraint: NSLayoutConstraint!
    
    var isBugDead = false
    
    var tap: UITapGestureRecognizer!
    let disposeBag = DisposeBag()
    
    let sqishPlayer: AVAudioPlayer
    
    required init?(coder: NSCoder) {
        let squishURL = Bundle.main.url(forResource: "squish", withExtension: ".caf")
        sqishPlayer = try! AVAudioPlayer(contentsOf: squishURL!)
        sqishPlayer.prepareToPlay()
        
        super.init(coder: coder)
        tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Observable.concat([
            openBasket(view, duration: 0.7),
            openNapkins(fabricTop, fabricBottom, duration: 1.0)
        ])
        .subscribe(onCompleted: {
            print(#function)
        }).disposed(by: disposeBag)
        
        moveBug()
        view.addGestureRecognizer(tap)
    }
    
    func moveBug() {
        Observable.concat([
            moveBugTo(bug, duration: 1.0, point: CGPoint(x: 75, y: 200)),
            delay(.seconds(1)),
            faceBug(bug, duration: 1.0, rotation: .pi),
            delay(.milliseconds(20)),
            moveBugTo(bug, duration: 1.0, point: CGPoint(x: self.view.frame.width - 75, y: 250)),
            delay(.seconds(1)),
            faceBug(bug, duration: 1.0, rotation: 0.0)
        ])
        .subscribe(onCompleted: { [unowned self] in
            guard !isBugDead else { return }
            moveBug()
        }).disposed(by: disposeBag)
    }
    
    func openBasket(_ view: UIView,
                    duration: TimeInterval) -> Observable<Void> {
        return Observable.create { [unowned self] (observer) -> Disposable in
            basketTopConstraint.constant -= basketTop.frame.size.height
            basketBottomConstraint.constant -= basketBottom.frame.size.height
            
            UIView.animate(withDuration: duration, animations: {
                view.layoutIfNeeded()
            }, completion: { _ in
                observer.onNext(())
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }

    func openNapkins(_ viewTop: UIView, _ viewBottom: UIView,
                     duration: TimeInterval) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
           
            UIView.animate(withDuration: duration, animations: {
                var fabricTopFrame = viewTop.frame
                fabricTopFrame.origin.y -= fabricTopFrame.size.height

                var fabricBottomFrame = viewBottom.frame
                fabricBottomFrame.origin.y += fabricBottomFrame.size.height

                viewTop.frame = fabricTopFrame
                viewBottom.frame = fabricBottomFrame
            }, completion: { _ in
                observer.onNext(())
                observer.onCompleted()
            })
            
            return Disposables.create()
        }

    }
    
    func moveBugTo(_ bug: UIView, duration: TimeInterval,
                 point: CGPoint) -> Observable<Void> {
        
        return Observable.create { (observer) -> Disposable in
            
        UIView.animate(withDuration: duration,
                       animations: {
                            bug.center = point
                       },
                       completion: { finished in
                        observer.onNext(())
                        observer.onCompleted()
               })
            return Disposables.create()
        }
    }
    
    func faceBug(_ bug: UIView, duration: TimeInterval,
                 rotation: CGFloat) -> Observable<Void> {
        
        return Observable.create { (observer) -> Disposable in
            UIView.animate(withDuration: duration,
                            animations: {
                            bug.transform = CGAffineTransform(rotationAngle: rotation)
                           }, completion: { finished in
                            observer.onNext(())
                            observer.onCompleted()
                           })
            return Disposables.create()
        }
    }
    
    func delay(_ duration: RxTimeInterval) -> Observable<Void> {
        return Observable.of(()).delay(duration, scheduler: MainScheduler.instance)
    }
    

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: bug.superview)
        
        if bug.layer.presentation()!.frame.contains(tapLocation) {
            print("Bug Tapped")
            
            guard !isBugDead else { return }
            view.removeGestureRecognizer(tap)
            
            isBugDead = true
            sqishPlayer.play()
            UIView.animate(withDuration: 0.7, delay: 0.0,
                           options: .curveEaseOut,
                           animations: {
                            self.bug.transform = CGAffineTransform(scaleX: 1.25, y: 0.75)
                           }, completion: { _ in
                            UIView.animate(withDuration: 2.0,
                                           animations: {
                                                self.bug.alpha = 0.0
                                           }, completion: { _ in
                                                self.bug.removeFromSuperview()
                                           })
                           })
        }
    }
}

