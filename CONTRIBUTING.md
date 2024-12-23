# Contribution Guide

このプロジェクトへのコントリビュート方法についてガイドです。

## Issues

次のIssueを受け付けています。

- 内容に対する質問 => [こちらから質問できます](https://github.com/ucd-tcc/ms-device-usage-report/issues/new?template=question.md)
- 内容のエラーや問題の報告 => [こちらからバグ報告できます](https://github.com/ucd-tcc/ms-device-usage-report/issues/new?template=bug_report.md)
- 解説の改善を提案 => [こちらから提案できます](https://github.com/ucd-tcc/ms-device-usage-report/issues/new?template=feature_request.md)

[その他のIssue](https://github.com/ucd-tcc/ms-device-usage-report/issues/new?template=other.md)も歓迎しています。

<br>

## Pull Request

Pull Requestはいつでも歓迎しています。  

基本的には、変更に関するIssueを立てた上でPull Requestの作成をしてください。  
ドキュメントの修正など、細かい内容のPull Requestについては、Issueを立てずにPull Requestを送ってもらって問題ありません。  

> [!NOTE]
> Pull Requestを送った内容は本プロジェクトの[ライセンス](./LICENSE)（**Mozilla Public License Version 2.0**）が適用されます。  
> [CODE OF CONDUCT](./.github/CODE_OF_CONDUCT.md)に反する内容を含むPull Requestは受け付けません。

### Pull Request作成手順  
以下の手順によって、Pull Requestを作成し、修正内容を送ってください。
1. 自身のリポジトリにForkする
2. 変更内容をcommitする
3. 既存のフォーマットに従って、Pull Request作成する
    ```
    ## 概要
    このPull Requestが解決する内容を簡単に説明してください。  
    また、**変更内容に関連のある項目をラベル付けしてください。**
    
    ## 変更点
    - 修正した具体的な内容を記載してください。
    - 変更点や意図を明確に説明してください。
    
    ## 背景
    なぜこの変更が必要か、背景を簡潔に説明してください。
    
    ## 関連するIssue
    - Issue番号: #
    
    ## 確認項目
    - [ ] 既存の機能への影響範囲を確認しました。
    - [ ] 修正した内容が期待通り動作することを確認しました。
    - [ ] 既存の他の機能への影響がないことを確認しました。
    - [ ] 関連するドキュメントが最新の状態に更新しました。
    
    ## その他
    レビュー時に注意すべきポイントや参考情報があれば記載してください。
    ```

4. [CODEOWNERS](./CODEOWNERS)による変更内容の承認
