<a name="top"></a>
<div align="right">
  <img src="./images/Logo/GIGA_Solution_gray.png" width="220">
  <img src="./images/Logo/Microsoft365_logo_horiz_c-gray_rgb.png" width="100">
  <img src="./images/Logo/WIN22_Windows11_logo_horiz_blue_cmyk.png" width="100">
</div>

# Microsoft 365 利用状況可視化テンプレート
GitHubとMicrosoft 365の機能を組み合わせ、Microsoft GIGAスクールパッケージの利用状況を蓄積・可視化するためのテンプレートです。
このREADMEでは、本テンプレートの概要や利用状況の蓄積に必要な環境構築手順を示します。  
  
<br/>
  
## 目次

- [本プロジェクトについて](#-本プロジェクトについて)
- [環境構築手順](#-環境構築手順)
- [各レポートの利用方法](#-各レポートの利用方法)
- [参考情報](#-参考情報)
  
<br/>
  

## 🚀 本プロジェクトについて

### 背景

文部科学省の[GIGAスクール構想の実現 学習者用コンピュータ最低スペック基準の一部訂正について（依頼）](https://www.mext.go.jp/content/20240201-mxt_shuukyo01-000033777_01.pdf)には、GIGAスクール構想で普及した端末の利用状況を把握する機能が必要であると記載されています。

> **2.9. 端末の稼働状況を把握できる機能について**
> 
> 本機能は、プライバシー保護に十分留意した上で、端末の利活用状況を客観的に把握するために具備する必要がある（文部科学省による端末の利活用状況の調査において、こうした客観的データに基づく回答を求めることとなる。）...

Microsoft 365 を利用している場合は、その利用ログから端末の利活用状況を把握することができます。  
しかし、Microsoft 365の[利用状況レポート機能](https://learn.microsoft.com/ja-jp/microsoft-365/admin/activity-reports/activity-reports?view=o365-worldwide)や[監査ログ機能](https://learn.microsoft.com/ja-jp/purview/audit-log-retention-policies?tabs=microsoft-purview-portal#default-audit-log-retention-policy)は単体では、本テンプレート作成時点では長期のログの保管・可視化ができません。
この問題を解決するため、Microsoft 365 の最小のライセンス構成(=A1ライセンス)での利用ログの長期保管や可視化ができるサンプルとして本テンプレートを公開します。


### 目的

本テンプレートの目的は以下の通りです。

- **Microsoft 365 利用状況レポートのデータ蓄積**:  
GIGAスクール構想で導入したMicrosoft 365 テナントの利用状況を年度単位で客観的に把握できるよう、日毎の利用状況レポートのデータをSharePoint Online サイトに長期的に保管可能とします。
- **蓄積したデータの可視化**:  
蓄積されたデータをPower BIを使ってわかりやすく可視化します。本テンプレート作成時点の文科省による利活用状況の調査例として、[全国学力・学習状況調査学校質問紙](https://www.nier.go.jp/24chousa/pdf/24shitsumonchousa_shou_gakkou.pdf)のICT機器の活用に対する設問を考慮し、人毎の利用頻度に基づいた可視化を行います。


### 概要

本テンプレートを導入することで、導入者が管理するMicrosoft 365上に利用状況レポートとその周辺データを保管するためのSharePoint Onlineサイトが開設されます。また、同じく導入者が管理するGitHub上に、各種データの参照・蓄積に必要なジョブを自動実行するためのGitHub Actionsが展開されます。日次でGitHub Actionsが自動実行されることで、SharePoint Onlineサイト上に日次のデータが保管されるようになります。  
  
また、手順に従ってPower BIをセットアップすることで、導入者のPower BI マイワークスペース上にデータを可視化するレポートが展開されます。日次でPower BIのデータ更新が自動実行されることで、レポートの内容も自動更新されるようになります。利用状況レポートの仕様や各種更新処理の都合から、レポートの内容は毎日正午12時過ぎに更新され、UTC基準の日付で2日前のデータまで表示されるようになります。    

導入後に開設されるシステムの構成図を以下に示します。  

**【システム構成図】**
```mermaid
graph BT
    subgraph Microsoft365 ["<div style='font-size:24px;'><b>Microsoft 365</b></div>"]
        usageReport["<div style='text-align: left;'><b>利用状況レポート</b><br>日毎のMicrosoft 365 の<br>利用結果データ</div>"]
        style usageReport fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        usageReportSetting["<div style='text-align: left;'><b>利用状況レポートの<br>匿名化設定</b></div>"]
        style usageReportSetting fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        UserData["<div style='text-align: left;'><b>Entra ID ユーザー情報</b></div>"]
        style UserData fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        subgraph SharePoint ["<b>SharePoint Online</b>"]
            usageRecords[("<div style='text-align: left;'><b>M365UsageRecords</b><br>利用状況レポート等の<br>データを保存</div>")]
            style usageRecords fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656
        end
        style SharePoint fill:#14858d,stroke:#565656,stroke-width:2px,color:#fff

        subgraph PowerBIService ["<b>Power BI サービス</b>"]
            powerBIReport["<div style='text-align: left;'><b>Power BI レポート</b><br>レポートを表示し<br>データを自動更新</div>"]
            style powerBIReport fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656
        end
        style PowerBIService fill:#e8b41b,stroke:#565656,stroke-width:2px,color:#fff

    end
    style Microsoft365 fill:#E5F1FB,stroke:#565656,stroke-width:2px,color:#565656

    subgraph GitHub ["<div style='font-size:24px;'><b>GitHub</b></div>"]
        subgraph githubRepo ["<b>GitHub リポジトリ</b>"]
            githubActions["<div style='text-align: left;'><b>GitHub Actions</b><br>・利用状況レポート等の<br>　データ取得<br>・SharePoint Onlineサイト<br>　へのデータ自動保存</div>"]
            style githubActions fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:8,color:#565656
        end
        style githubRepo fill:#F6F8FA,stroke:#565656,stroke-width:2px,color:#565656
    end
    style GitHub fill:#848F9C,stroke:#565656,stroke-width:2px,color:#fff

    user["<div style='text-align: left;'><b>レポート利用者</b><br>Power BI レポートを利用</div>"]
    style user fill:#565656,stroke:#565656,stroke-width:2px,color:#fff

    GitHub -->|データを取得| usageReport
    GitHub -->|データを取得| usageReportSetting
    GitHub -->|データを取得| UserData
    GitHub -->|データを保存| usageRecords
    powerBIReport -->|データを参照| usageRecords
    user -->|レポートを閲覧| powerBIReport
    linkStyle 0 stroke:#565656, stroke-width:1.5px;
    linkStyle 1 stroke:#565656, stroke-width:1.5px;
    linkStyle 2 stroke:#565656, stroke-width:1.5px;
    linkStyle 3 stroke:#565656, stroke-width:1.5px;
    linkStyle 4 stroke:#565656, stroke-width:1.5px;
    linkStyle 5 stroke:#565656, stroke-width:1.5px;
```

**【レポート画面】**
  |<img src="./images/Report/Report_1.png" width="100%">|
  |---------|  


### 👨‍💻👩‍💻 対象者
Microsoft 365 のグローバル管理者アカウントが利用可能なMicrosoft 365テナントのシステム管理者  


### 🎈 前提条件  
1. **PC**  
セットアップ用のスクリプト実行やPower BI Desktopを利用するため、以下の要件を満たすPCを用意します。  

    | OS | 動作確認済みのバージョン |
    |:-|:-|
    | Windows 10 | 22H2 |
    | Windows 11 | 24H2 |

> [!CAUTION]
> PCのシステムロケールが日本である必要があります。

2. **ネットワーク**  
資源のインストールやAPI実行を行うため、インターネット接続ができる環境を用意します。  
  
3. **Microsoft 365 ライセンス**  
本プロジェクトのレポートを活用するためには、最低でもMicrosoft 365 A1 ライセンスが必要です。  
  
4. **Microsoft 365 アカウントおよびグループ**  
本プロジェクトの可視化テンプレートの利用に際しては、本READMEに従ってMicrosoft 365 のログを蓄積するための環境構築が必要です。  
環境構築にはMicrosoft 365 のグローバル管理者アカウントが必要となります。  
また、本テンプレートでは2種類のレポートを公開しており、その種類ごとに以下のアカウントまたはグループが必要となります。  

    | レポート種別 | 必要なアカウントまたはグループ |
    |:-|:-|
    | [010_テナントの利用状況可視化サンプル](./src/010_テナントの利用状況可視化サンプル/README.md) | レポートの参照を許可する個別のアカウント。自治体のシステム管理者を想定。 |
    | [020_学校毎の利用状況可視化サンプル](./src/020_学校毎の利用状況可視化サンプル/README.md)   | レポートの参照を許可する個別のアカウント。自治体のシステム管理者を想定。後述手順にて"**M365UsageRecords_site_access_group**"のメンバーに追加する。 |
> [!NOTE]
> グループについては、セキュリティグループでもM365グループでもどちらでも問題ないです。  

> [!CAUTION]
> レポートにはMicrosoft 365 利用状況レポートのデータが含まれるため、該当データを参照可能な[管理者アカウント](https://learn.microsoft.com/ja-jp/microsoft-365/admin/activity-reports/activity-reports?view=o365-worldwide#who-can-see-reports)の保有者にのみレポートの参照を許可することを推奨します。  他のアカウントにレポートの参照を許可したい場合は、組織のセキュリティポリシーを考慮の上ご利用ください。  
  
5. **その他**  
レポートの種類ごとに、前提となる設定や運用に違いがあります。  
    
    | レポート種別 | 想定利用者 | ログ匿名化設定(※1) | 名簿情報の運用(※2)  |
    |:-|:-|:-|:-|
    | [010_テナントの利用状況可視化サンプル](./src/010_テナントの利用状況可視化サンプル/README.md) | 自治体のシステム管理者 | 有効 or 無効 | 無 |
    | [020_学校毎の利用状況可視化サンプル](./src/020_学校毎の利用状況可視化サンプル/README.md)   | 自治体のシステム管理者 | 無効 | 有 |

**※1 ログ匿名化設定**:  
2021年9月1日以降、Microsoft 365 上の利用状況レポートのユーザー識別情報は既定で匿名化されています。  
学校毎の利用状況を集計する場合は、[匿名化をオフにする](https://learn.microsoft.com/ja-jp/microsoft-365/troubleshoot/miscellaneous/reports-show-anonymous-user-name#resolution)必要があります。  

**※2 名簿情報の運用**:  
学校毎の利用状況を集計する場合は、Microsoft 365 アカウントごとの学校等の所属情報が必要となります。  
Microsoft 365 テナントによって所属情報の運用方法は異なるため、本テンプレートではMicrosoft 365上の所属情報は参照せず、別途[所属情報の名簿をExcelで作成](./src/020_%E5%AD%A6%E6%A0%A1%E6%AF%8E%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/README.md#1-%E5%90%8D%E7%B0%BF%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AE%E6%BA%96%E5%82%99)する構成としています。**名簿は少なくとも年度ごとに1つ登録する必要があります。**  
  
<br/>
  
## 📝 環境構築手順

以下に利用状況の蓄積に必要な環境構築の手順を示します。  
本手順実施後、別途レポートの利用方法に従ってレポートの構築も実施してください。  
  
### 1. 環境構築に必要なツールのインストール

環境構築を行うために、事前に以下に示すツールが必要です。未インストールの場合やバージョンが古い場合は以下の手順でインストールします。
> [!NOTE]
> 手順の中のスクリーンショットは2024/12/02時点での画面です。現在の画面とは異なる場合がございます。

- Gitのインストール

Windows PowerShellで以下のコマンドを実行します。  
```shell
winget install --id Git.Git -e --source winget
```
※動作確認済version：2.47.0.windows.2  


コマンドが実行できなかった場合は、[こちら](https://gitforwindows.org/)から.exeファイルをダウンロード後、以下の手順でインストールを行います。

<details>
<summary>クリックして手順を表示　</summary>
    
> 1. ダウンロードした.exeファイルをダブルクリックして実行します。
> 2. デフォルトの設定から変更せず、[Install] が表示されるまで [Next] をクリックします。  
> 
> |![Gitのインストール1](./images/Install/Install_Git_1.png)|
> |---|
> 3. [Install] をクリックします。
> 
> |![Gitのインストール2](./images/Install/Install_Git_2.png)|
> |---|
> 4. インストール完了後、以下の画面が表示されるため [Finish] をクリックします。  
> その後、ブラウザでページが表示されますが、閉じて構いません。
> 
> |![Gitのインストール3](./images/Install/Install_Git_3.png)|
> |---|
</details>

- GitHub CLIのインストール

Windows PowerShellで以下のコマンドを実行します。
```shell
winget install --id GitHub.cli
```
※動作確認済version：2.60.1  


コマンドが実行できなかった場合は、[こちら](https://cli.github.com/)から.msiファイルをダウンロード後、以下の手順でインストールを行います。
<details>
<summary>クリックして手順を表示　</summary>

> 1. ダウンロードした.msiファイルをダブルクリックして実行します。
> 2. デフォルトの設定から変更せず、[Install] が表示されるまで [Next] をクリックします。  
> 
> |![GitHub CLIのインストール1](./images/Install/Install_GitHub_CLI_1.png)|
> |---|
> 3. [Install] をクリックします。  
> 
> |![GitHub CLIのインストール2](./images/Install/Install_GitHub_CLI_2.png)|
> |---|
> 4. インストール完了後、以下の画面が表示されるため [Finish] をクリックします。  
> 
> |![GitHub CLIのインストール3](./images/Install/Install_GitHub_CLI_3.png)|
> |---|
</details>

- Azure CLIのインストール

Windows PowerShellで以下のコマンドを実行します。
```shell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait
```
※動作確認済version：2.65.0   

コマンドが実行できなかった場合は、[こちら](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli-windows?tabs=azure-cli)から.msiファイルをダウンロード後、以下の手順でインストールを行います。  
<details>
<summary>クリックして手順を表示　</summary>

> 1. ダウンロードした.msiファイルをダブルクリックして実行します。
> 2. チェックボックスにチェックを入れて、[Install] をクリックします。  
> 
> |![Azure CLIのインストール1](./images/Install/Install_Azure_CLI_1.png)|
> |---|
> 3. インストール完了後、以下の画面が表示されるため [Finish] をクリックします。  
>
> |![Azure CLIのインストール2](./images/Install/Install_Azure_CLI_2.png))|
> |---|
</details>

### 2. GitHubアカウントの作成
環境構築を行うために、作業者のMicrosoft 365 アカウントと紐づくGitHubアカウントを作成します。
> [!NOTE]
> 作業者のアカウントと紐づくGitHubアカウントが存在する場合は、「3. **GitHubアカウントの二要素認証の設定**」に移動します。

<details>
<summary>クリックして手順を表示　</summary>
  
> 1. [GitHub](https://github.com/)にアクセスします。
> 2. Microsoft 365 グローバル管理者アカウントのメールアドレスを入力後、[Sign up for GitHub] をクリックします。
>  
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_1.png" width="600">|
> |---|
> 3. ユーザー名/パスワードを設定し、[Continue] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_2.png" width="600">|
> |---|
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_3.png" width="600">|
> 4. [Verify] をクリックした後に、画面の指示通りに認証を行います。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_4.png" width="600">|
> |---|
> 5. 2.で入力したメールアドレスに届く8桁のコードを入力します。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_5.png" width="600">|
> |---|
> 6. 画面が切り替わったら、3.で設定したユーザー名とパスワードを入力して、[Sign in] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_6.png" width="600">|
> |---|
> 7. [Skip personalization] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Account_7.png" width="600">|
> |---|
</details>

### 3. GitHubアカウントの二要素認証の設定
GitHubアカウントへの不正アクセスが生じると機密情報にアクセスされるリスクがあります。  
アカウントへの不正アクセスを防ぐために、GitHubアカウントにログイン後、[こちら](https://docs.github.com/ja/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)を参考にして、二要素認証を有効にします。  
TOTPアプリケーション（Microsoft Authenticator等）を用いた二要素認証の設定を推奨します。

### 4. GitHub組織の作成
環境構築を行うために、GitHubアカウントと紐づくGitHub組織を作成します。  

<details>
<summary>クリックして手順を表示　</summary>

> 1. GitHubアカウントにログイン後、右上のアイコンをクリックし、[Your Organizations] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_1.png" width="600">|
> |---|
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_2.png" width="600">|
> 2. [New Organization] をクリックした後に、[Create a free organization] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_3.png" width="600">|
> |---|
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_4.png" width="600">|
> 3. 組織名と任意のメールアドレスを入力します。特に指定がない場合は、[My personal account] をクリックします。  
> 現在のアカウントではなく、組織のアカウントに紐づける場合は [A business or institution] をクリックします。  
> その後、[Verify] をクリックし、画面の指示通りに認証を行います。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_5.png" width="600">|
> |---|
> 4. チェックボックスにチェックを入れ、[Next] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_6.png" width="600">|
> |---|
> 5. 特に指定がない場合は、[Skip this step] をクリックします。  
> メンバーを追加する場合は、メンバーを選択後 [Complete setup] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_7.png" width="600">|
> |---|
</details>

### 5. GitHub組織のリポジトリの作成
日次でMicrosoft 365 の利用ログの収集やSharePoint Online サイトへのデータアップロードを行うGitHub Actionsワークフローを動かすために、GitHubリポジトリの作成を行います。  
> [!NOTE]
> リポジトリをpublicに設定してしまった場合やREADMEファイルが作成されていない場合は、リポジトリを作成し直してください。

<details>
<summary>クリックして手順を表示　</summary>

> 1. GitHubアカウントにログイン後、右上のアイコンをクリックし、[Your Organizations] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_1.png" width="600">|
> |---|
> |<img src="./images/Setup_GitHub/Create_GitHub_Organization_2.png" width="600">|
> 2. 「4. **GitHub組織の作成**」で作成した組織名もしくは、すでに作成済みの組織を選択します。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Repository_1.png" width="600">|
> |---|
> 3. 左上のタブから、[Repositories] をクリックした後に、[New repository] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Repository_2.png" width="600">|
> |---|
> |<img src="./images/Setup_GitHub/Create_GitHub_Repository_3.png" width="600">|
> 4. リポジトリ名を入力します。**必ず、[Private]を選択し、[Add a README file]にチェックを入れてください。**  
> その後、[Create repository] をクリックします。
> 
> |<img src="./images/Setup_GitHub/Create_GitHub_Repository_4.png" width="600">|
> |---|
</details>

### 6.  **GitHubリポジトリの内容をローカルにクローン**  
Windows PowerShellで以下のコマンドを任意の場所で実行します。
```shell
git clone https://github.com/uchidayoko/ms-giga-usage-report.git
``` 

### 7. 設定ファイルの編集
「6. **GitHubリポジトリの内容をローカルにクローン** 」でローカルにコピーした`ms-giga-usage-report`フォルダ内の`params.json`ファイルにおける下表の4項目を編集し、上書き保存します。  
`params.json`ファイルは、`ms-giga-usage-report/src/000_setup/params.json`に存在します。
| パラメータ | 設定値 |
|---------|---------|
|githubOrganizationName| GitHubの組織名を入力します。(「4. **GitHub組織の作成**」 で設定した組織名)|
|githubRepositoryName|作成したGitHub組織のリポジトリ名を入力します。（「5. **GitHub組織のリポジトリの作成**」 で設定したリポジトリ名）|
|githubAccountName| GitHubアカウント名を入力します。（「2. **GitHubアカウントの作成**」 で設定したアカウント名）|
|githubAccountMail|GitHubアカウントに紐づいているメールアドレスを入力します。（「2. **GitHubアカウントの作成**」 で入力したメールアドレス）|
|sharepointDomain|Microsoft 365 アカウントのSharePointサイトにおけるURLのドメイン名を入力します。（確認方法は以下の手順を参照）|

<details>
<summary>クリックして手順を表示　</summary>

> 1. Microsoft Edgeを起動後、左上のランチャーを展開し、[SharePoint]をクリックします。
> 
> |<img src="./images/Check_SharePoint_URL/Check_SharePoint_URL_1.png" width="600">|
> |---|
> |<img src="./images/Check_SharePoint_URL/Check_SharePoint_URL_2.png" width="600">|
> 2. ブラウザの上部に表示されるURLから、「https://」以降の「.sharepoint.com」までの文字列がSharePointサイトにおけるURLのドメイン名となります。
> この文字列をコピーし、`params.json`ファイルの"sharepointDomain"の部分にペーストします。
> 
> |<img src="./images/Check_SharePoint_URL/Check_SharePoint_URL_3.png" width="600">|
> |---|
</details>

例) githubOrganizationName="TestOrganization", githubRepositoryName="TestRepository", githubAccountName="testGithubAccountName", githubAccountMail="<span>aaa</span>@contoso.com", SharePointのURL="<span>https</span>://contoso.sharepoint.com"の場合  

```json
{
    "githubOrganizationName": "TestOrganization",
    "githubRepositoryName": "TestRepository",
    "githubAccountName": "testGithubAccountName",
    "githubAccountMail": "aaa@contoso.com",
    "sharepointDomain": "contoso.sharepoint.com"
}
```

### 8. デプロイスクリプトの実行 
「6. **GitHubリポジトリの内容をローカルにクローン** 」でローカルにコピーした`ms-giga-usage-report`フォルダ内の`exec.bat`ファイルをダブルクリックして実行します。  
`exec.bat`ファイルは、`ms-giga-usage-report/src/000_setup/exec.bat`に存在します。  
> [!NOTE]
> 実行に失敗した場合は、「7. **設定ファイルの編集** 」で設定したローカルの`params.json`の内容を確認し、`exec.bat`ファイルを再実行してください。

<details>
<summary>クリックして手順を表示　</summary>

> - GitHub CLIへのログイン
> 1. Windows PowerShellに以下の画面が表示されたら、Enterを押します。
> 
> |<img src="./images/Login/Login_GitHub_CLI_1.png" width="600">|
> |---|
> 2. 画面上の8桁のコードをコピーして、Enterを押します。
> 
> |<img src="./images/Login/Login_GitHub_CLI_2.png" width="600">|
> |---|
> 3. [Continue] をクリックした後に、2.でコピーした8桁のコードをペーストし、再び [Continue] をクリックします。
> 
> |<img src="./images/Login/Login_GitHub_CLI_3.png" width="600">|
> |---|
> |<img src="./images/Login/Login_GitHub_CLI_4.png" width="600">|
> 4. [Authorize github] をクリックします。その後、パスワードの入力が求められた場合は、パスワードを入力します。
> 
> |<img src="./images/Login/Login_GitHub_CLI_5.png" width="600">|
> |---|
> 5. 以下の画面が表示されたら、GitHub CLIへのログインは完了です。この画面は閉じて構いません。
> 
> |<img src="./images/Login/Login_GitHub_CLI_6.png" width="600">|
> |---|
> 
> - Azure CLIへのログイン
> 1. 以下のポップアップが表示されたら、ご自身のMicrosoft 365 アカウントを選択し、[Continue] をクリックします。  
> その後、パスワードの入力が求められた場合は、パスワードを入力します。
> 
> |<img src="./images/Login/Login_Azure_CLI_1.png" width="600">|
> |---|
> 2. Windows PowerShellに以下の画面が表示されたら、構築先のテナントを示す数字を入力し、Enterを押します。
> 
> |<img src="./images/Login/Login_Azure_CLI_2.png" width="600">|
> |---|
>
> - Azureアカウントへのログイン
> 1.  以下のポップアップが表示されたら、ご自身のMicrosoft 365 アカウントを選択し、[Continue] をクリックします。  
> その後、パスワードの入力が求められた場合は、パスワードを入力します。
>
> |<img src="./images/Login/Login_Azure_Account_1.png" width="600">|
> |---|
>
> 2. Windows PowerShellに以下の画面が表示されたら、構築先のテナントを示す数字を入力し、Enterを押します。
> 
> |<img src="./images/Login/Login_Azure_Account_2.png" width="600">|
> |---|
> 
> - Microsoft Graphへのログイン
> 1. ブラウザが立ち上がり、以下の画面が表示されたら、ご自身のMicrosoft 365 アカウントを選択します。  
> その後、パスワードの入力が求められた場合は、パスワードを入力します。
> 
> |<img src="./images/Login/Login_Microsoft_Graph_1.png" width="600">|
> |---|
>
> 2. チェックボックスにチェックを入れ、[承諾] をクリックします。
>
> |<img src="./images/Login/Login_Microsoft_Graph_2.png" width="600">|
> |---|
> 
> 3. 以下の画面が表示されたら、Microsoft Graphアカウントへのログインは完了です。この画面は閉じて構いません。
> 
> |<img src="./images/Login/Login_Microsoft_Graph_3.png" width="600">|
> |---|
>
> - SharePoint Online管理シェルへのログイン
> 1. 以下のポップアップが表示されたら、ご自身のMicrosoft 365 アカウントを選択します。  
> その後、パスワードの入力が求められた場合は、パスワードを入力します。
> 
> |<img src="./images/Login/Login_SPO_Service_1.png" width="600">|
> |---|
</details>

### 9. 動作確認
SharePoint Online サイトにMicrosoft 365 利用ログが出力されているかを確認します。  
SharePoint Online サイトのURLは以下になります。（ローカルにコピーした`output.json`ファイル内の"siteUrl"に記載されています。）  

**「https://{「7. **設定ファイルの編集**」で設定した"sharepointDomain"}/sites/M365UsageRecords」**  

例）Microsoft 365 アカウントのSharePointサイトにおけるURLが "<span>https</span>://contoso.sharepoint.com"の場合

**「<span>https</span>://contoso.sharepoint.com/sites/M365UsageRecords」**

> [!NOTE]
> データが正しく出力されていない場合は、`reset.bat`ファイルをダブルクリックして実行し、「8. **デプロイスクリプトの実行**」で構築した環境を削除します。
> `reset.bat`ファイルは、`ms-giga-usage-report/src/000_setup/reset.bat`に存在します。  
> 「5. **GitHub組織のリポジトリの作成**」を参考に、リポジトリを再度作成した後に、**前提条件**や「7. **設定ファイルの編集** 」で設定したローカルの`params.json`の内容に誤りがないか確認します。  
> その後、「8. **デプロイスクリプトの実行**」を参考に、`exec.bat`ファイルを再実行します。

<details>
<summary>クリックして手順を表示　</summary>

> 1. SharePoint Onlineサイトにアクセスします。  
> 
> 2. 左側のタブから、[ドキュメント] をクリックします。
> 
> |<img src="./images/Access/Access_SharePoint_1.png" width="600">|
> |---|
> 3. 「**M365UsageRecords/M365UsageReports/{"Concealed" or "UnConcealed"}/M365AppUserDetail/school_year={現在の年度}**」
> とフォルダを選択していき、csvファイルが存在することを確認します。
>
> |<img src="./images/Access/Access_SharePoint_2.png" width="600">|
> |---|
> |<img src="./images/Access/Access_SharePoint_3.png" width="600">|
> |<img src="./images/Access/Access_SharePoint_4.png" width="600">|
> |<img src="./images/Access/Access_SharePoint_5.png" width="600">|
> |<img src="./images/Access/Access_SharePoint_6.png" width="600">|
> |<img src="./images/Access/Access_SharePoint_7.png" width="600">|
</details>

### 10. アクセス権設定  
これまでの構築作業で、Microsoft 365 の利用ログや現在Entra ID上に登録されているユーザー情報がSharePoint Onlineサイト上に追加されるようになりました。  
しかし、他のユーザーがPower BIのレポートを閲覧する場合は以下の手順による権限設定が必要です。  

<details>
<summary>クリックして手順を表示　</summary>

> 1.  [Azure Portal](https://portal.azure.com/)にログインします。
>
> 2. Azure サービスから、[Microsoft Entra ID] をクリックします。
>
> |<img src="./images/Access/Access_Azure_1.png" width="600">|
> |---|
>
> 3. 左側のタブから、[グループ] > [すべてのグループ] をクリックします。
>
> |<img src="./images/Access/Access_Azure_2.png" width="600">|
> |---|
> |<img src="./images/Access/Access_Azure_3.png" width="600">|
>
> 4. グループの中から、"**M365UsageRecords_site_access_group**"を選択します。
>
> |<img src="./images/Access/Access_Azure_4.png" width="600">|
> |---|
>
> 5. 左側の [管理] タブを展開し、[メンバー] をクリックします。
>
> |<img src="./images/Access/Access_Azure_5.png" width="600">|
> |---|
> |<img src="./images/Access/Access_Azure_6.png" width="600">|
> 
> 6. 上側のタブから、[メンバーの追加] をクリックし、レポートを参照するユーザーを追加します。  
>
> |<img src="./images/Access/Access_Azure_7.png" width="600">|
> |---|

</details>

> [!NOTE]
> 環境構築したユーザー以外がレポートを利用する場合のみ実施する。

> [!CAUTION]
> レポートにはMicrosoft 365 利用状況レポートのデータが含まれるため、該当データを参照可能な[管理者アカウント](https://learn.microsoft.com/ja-jp/microsoft-365/admin/activity-reports/activity-reports?view=o365-worldwide#who-can-see-reports)の保有者にのみレポートの参照を許可することを推奨します。  他のアカウントにレポートの参照を許可したい場合は、組織のセキュリティポリシーを考慮の上ご利用ください。  
 
<br/>
  
## 📃 各レポートの利用方法

前提条件別に以下のレポートを公開しています。リンク先の手順に従ってそれぞれ利用方法を確認・実施してください。  
- [010_テナントの利用状況可視化サンプル](./src/010_テナントの利用状況可視化サンプル/README.md)
- [020_学校毎の利用状況可視化サンプル](./src/020_学校毎の利用状況可視化サンプル/README.md)  
※利用のためには各Microsot 365 IDがどの学校に所属しているのかを示す名簿ファイルの作成が必要
  
<br/>
  
## 📚 参考情報

本プロジェクトに関連するドキュメント
- [GIGA スクール構想の実現 学習者用コンピュータ最低スペック基準の一部訂正について（依頼）](https://www.mext.go.jp/content/20240201-mxt_shuukyo01-000033777_01.pdf)
- [Microsoft 365 レポートに実際のユーザー名ではなく匿名のユーザー名が表示される -Microsoft 365](https://learn.microsoft.com/ja-jp/microsoft-365/troubleshoot/miscellaneous/reports-show-anonymous-user-name#resolution)
- [Git for Windows](https://gitforwindows.org/)
- [GitHub Cli](https://cli.github.com/)
- [Windows での Azure CLI のインストール](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli-windows?tabs=azure-cli)
- [GitHub Docs 2 要素認証を設定する](https://docs.github.com/ja/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)


[Back to top](#top)
