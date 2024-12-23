<a name="top"></a>

# Microsoft 365 テナント全体の利用状況可視化サンプル利用ガイド

Microsoft 365 テナント全体の利用状況可視化サンプルのPBITファイルのセットアップと利用方法を解説します。

## 目次

- [対象者](#-対象者)
- [概要](#-概要)
- [前提条件](#-前提条件)
- [事前準備](#-事前準備)
- [利用開始手順](#-利用開始手順)
- [レポートの閲覧方法](#レポートの閲覧方法)
- [取得データ期間の変更方法](#-取得データ期間の変更方法)
- [注意事項](#-注意事項)
- [関連情報](#-関連情報)

## 👨‍💻👩‍💻 対象者

本ガイドは、Microsoft 365 テナント全体の利用状況可視化サンプルを閲覧するユーザーが対象です。  
主な利用者はシステム管理者を想定しています。

## 💻 概要

テナント全体のMicrosoft 365 の利用状況を可視化します。  
利用日数に応じて区分された利用人数および利用率を集計します。

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
            subgraph SharePointSite ["<b>M365UsageRecords サイト</b>"]
                roster[("<div style='text-align: left;'><b>MgUser(Roster)</b><br>Entra ID ユーザー情報<br>を記載したCSVファイル</div>")]
                style roster fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656

                usageRecords[("<div style='text-align: left;'><b>M365UsageRecords</b><br>利用状況レポートのデータ<br>等を記載したCSVファイル</div>")]
                style usageRecords fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656
            end
            style SharePointSite fill:#F6F8FA,stroke:#565656,stroke-width:2px,color:#565656
        end
        style SharePoint fill:#14858d,stroke:#565656,stroke-width:2px,color:#fff

        subgraph PowerBIService ["<b><br>Power BI サービス</b>"]
            powerBIReport["<div style='text-align: left;'><b>Power BI レポート</b><br>レポートを表示し<br>データを自動更新</div>"]
            style powerBIReport fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656
        end
        style PowerBIService fill:#e8b41b,stroke:#565656,stroke-width:2px,color:#fff

    end
    style Microsoft365 fill:#E5F1FB,stroke:#565656,stroke-width:2px,color:#565656

    subgraph GitHub ["<div style='font-size:24px;'><b>GitHub</b></div>"]
        subgraph githubRepo ["<b>GitHub リポジトリ</b>"]
            githubActions["<div style='text-align: left;'><b>GitHub Actions</b><br>・利用状況レポート等の<br>　データ取得<br>・SharePoint Online サイト<br>　へのデータ自動保存</div>"]
            style githubActions fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656
        end
        style githubRepo fill:#F6F8FA,stroke:#565656,stroke-width:2px,color:#565656
    end
    style GitHub fill:#848F9C,stroke:#565656,stroke-width:2px,color:#fff

    user["<div style='text-align: left;'><b>レポート利用者</b><br>Power BI レポートを利用</div>"]
    style user fill:#565656,stroke:#565656,stroke-width:2px,color:#fff

    powerBIReport -->|データを参照| SharePointSite
    GitHub -->|データを取得| usageReport
    GitHub -->|データを取得| usageReportSetting
    GitHub -->|データを取得| UserData
    GitHub -->|データを保存| usageRecords
    GitHub -->|データを保存| roster
    user -->|レポートを閲覧| powerBIReport
    linkStyle 0 stroke:#565656, stroke-width:1.5px;
    linkStyle 1 stroke:#565656, stroke-width:1.5px;
    linkStyle 2 stroke:#565656, stroke-width:1.5px;
    linkStyle 3 stroke:#565656, stroke-width:1.5px;
    linkStyle 4 stroke:#565656, stroke-width:1.5px;
    linkStyle 5 stroke:#565656, stroke-width:1.5px;
    linkStyle 6 stroke:#565656, stroke-width:1.5px;
```

**【レポート画面】**

|<img src="images/Report_010_Explanation.png" width="600">|
|---------|

画像の番号ごとにレポートの概要を説明します。

| 番号 | 概要 |
|---------|---------|
| ① | 集計対象の年度を選択します。複数選択も可能です。 |
| ② | 集計対象のデータ期間を表します。 |
| ③ | 集計期間において、利用頻度ごとに利用人数を集計します。 |
| ④ | 利用頻度毎の利用人数を月別に表示します。 |
| ⑤ | 利用頻度毎の利用人数を機能（アプリ）別に表示します。 |
| ⑥ | 利用頻度毎の利用人数を週別に表示します。 |
| ⑦ | 表示しているデータについて、補足や留意事項を記載しています。 |

集計に利用している利用頻度は以下のように定義しています。
| 利用頻度 | 説明 |
|---------|---------|
| 週 5 日以上 | 集計期間の日数のうち、5/7 以上利用している |
| 週 3 日以上 | 集計期間の日数のうち、3/7 以上・5/7 未満利用している |
| 週 1 日以上 | 集計期間の日数のうち、1/7 以上・3/7 未満利用している |
| 月 1 日以上 | 集計期間の日数のうち、12/365 以上・1/7 未満利用している |
| 月 1 日未満 | 集計期間の日数のうち、12/365 未満利用している、または利用していない<br>※利用していない人数には、Microsoft 365 上に存在する有効なアカウントをすべて含みます。 |

> [!NOTE]
> + 新入生および卒業生は、在籍期間を対象として利用頻度が集計されます。
> + 利用人数の総数は、ライセンス割当済かつ削除されていない一意のMicrosoft 365 アカウント数から算出しています。

## ✅ 前提条件

Microsoft 365 テナント全体の利用状況可視化サンプルを使用するには以下の前提条件を満たす必要があります。

1. **環境構築**  
   テナントのシステム管理者によって、 [環境構築手順](/README.md#-%E7%92%B0%E5%A2%83%E6%A7%8B%E7%AF%89%E6%89%8B%E9%A0%86) が完了していることを確認してください。

2. **Microsoft 365 アカウント**  
   Power BI Desktop や Power BI サービスにサインインするための有効な Microsoft 365 アカウントが必要です。

3. **Microsoft 365 A1ライセンス**  
   本プロジェクトのレポートを活用するためには、最低でもMicrosoft 365 A1ライセンスが必要です。  

4. **インターネット接続**  
   Power BI Desktop からデータソースとなる SharePoint Online へのアクセスやPower BI サービスのアクセスにインターネット接続が必須です。

5. **Power BI Desktop のインストール**  
   PCに Power BI Desktop がインストールされていることを確認してください。  
   詳細は[こちら（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop) の手順に従ってください。  

> [!IMPORTANT]
> + インストールのための [最小要件（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop#minimum-requirements) を確認して下さい。
> + 端末のメモリ (RAM) が 4 GB 以下だと動作しない可能性があります。

> [!NOTE]
> + Power BI Desktop のインストールにはPCの管理者権限が必要になる場合があります。
> + Power BI Desktop の起動後、「WebView2に問題があります」と表示された場合は以下のMicrosoft Learnを参考にしてください。
>   [Power BI Desktop の起動に関する問題を解決する - Power BI | Microsoft Learn<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/connect-data/desktop-error-launching-desktop)

6. **データソースへのアクセス権**  
   SharePoint Online サイト上のデータソースへのアクセス権限を持っていることを確認してください。

> [!NOTE]
> + データソースとなるサイトのURLは、[環境構築手順　9. 動作確認](/README.md#9-%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D) に記載されています。
> + アクセス権限が無い場合は [データソースへのアクセス権設定](/README.md#-%E3%83%87%E3%83%BC%E3%82%BF%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%B8%E3%81%AE%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E6%A8%A9%E8%A8%AD%E5%AE%9A) を実施してください。

## 📥 事前準備

### 1. GitHubからのPBITファイルのダウンロード

レポートを利用開始するために、以下の手順でテンプレートをダウンロードできます。

<details>
<summary>　クリックして詳細表示</summary>

> 1. [テンプレートファイル<img src="images/link-external.svg">](https://github.com/uchidayoko/ms-giga-usage-report/blob/main/src/010_%E3%83%86%E3%83%8A%E3%83%B3%E3%83%88%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/01_%E3%83%86%E3%83%8A%E3%83%B3%E3%83%88%E5%85%A8%E4%BD%93%E3%81%AE%E7%AB%AF%E6%9C%AB%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E3%83%AC%E3%83%9D%E3%83%BC%E3%83%88.pbit) をダウンロードします。
> 
> |<img src="images/Download_Template_File_1.jpg" width="600">|
> |---------|

</details>

### 2. Power BI Desktop へのサインイン

初回利用時には、Power BI Desktop にサインインする必要があります。

<details>
<summary>　クリックして詳細表示</summary>

> 1. Windows のスタートメニューから、Power BI Desktop を起動します。  
>    + 起動後にサインインを求められた場合は、手順4 に進んでください。
> 
> 2. 画面左下の [サインイン] をクリックします。
> 
> |<img src="images/SignIn_Power_BI_Desktop_1.jpg" width="600">|
> |---------|
> 
> 3. 画面表示に従い、Microsoft 365 アカウントのメールアドレスを入力します。
> 
> |<img src="images/SignIn_Power_BI_Desktop_2.jpg" width="600">|
> |---------|
> 
> 4. ご自身のMicrosoft 365 アカウントでサインインします。
> 
> |<img src="images/SignIn_Power_BI_Desktop_3.jpg" width="600">|
> |---------|
> 
> 5. Power BI Desktop の画面右上に、ご自身のアカウント名が表示されていることを確認します。
> 
> |<img src="images/SignIn_Power_BI_Desktop_4.jpg" width="600">|
> |---------| 
> 
> 6. Power BI Desktop の画面は利用しないため、閉じて構いません。

</details>

### 3. Power BI サービスへのサインイン

初回利用時には、Power BI サービスにサインインする必要があります。

<details>
<summary>　クリックして詳細表示</summary>

> 1. 以下のWebページにアクセスします。  
>    [始める | Microsoft Power BI<img src="images/link-external.svg">](https://www.microsoft.com/ja-jp/power-platform/products/power-bi/getting-started-with-power-bi)
> 
> 2. 右上の [サインイン] からPower BI サービスにサインインします。  
> 
> |<img src="images/SignIn_Power_BI_Service_1.jpg" width="600">|
> |---------|
> 
> 3. 画面の指示に従いメールアドレスを入力して [送信] します。
> 
> |<img src="images/SignIn_Power_BI_Service_2.jpg" width="600">|
> |---------|
> |<img src="images/SignIn_Power_BI_Service_3.jpg" width="600">|

</details>

### 4. 「Microsoft Fabric Free」ライセンスの有効化

Microsoft 365 A1 / A3 ライセンスの場合は、「Microsoft Fabric Free」ライセンスを有効化する必要があります。

> [!NOTE]
> + Microsoft 365 A5 ライセンスには「Power BI Pro」ライセンスが含まれるため、こちらの手順は不要です。
> + 詳細手順のような画面が表示されない場合もこちらの手順は不要です。
> + Microsoft Fabric の「無料試用版」を有効化する必要はありません。

<details>
<summary>　クリックして詳細表示</summary>

> 1. サービス画面上の指示に従い、「Microsoft Fabric Free」ライセンスを開始します。
> 
> |<img src="images/Setup_Fabric_Free_1.jpg" width="600">|
> |---------|
> |<img src="images/Setup_Fabric_Free_2.jpg" width="600">|
> |<img src="images/Setup_Fabric_Free_3.jpg" width="600">|
> 
> 2. Power BI サービスが開きます。右上の「人アイコン」をクリックし、  
>    「ライセンスの種類：無料アカウント」と表示されていることを確認します。
> 
> |<img src="images/Setup_Fabric_Free_4.jpg" width="600">|
> |---------|

</details>

## 📝 利用開始手順

### 1. PBITファイルの利用開始

以下の手順に従い、テンプレートをPower BI Desktop で開きます。

> [!NOTE]
> + 不具合が生じた場合は「[前提条件](#-前提条件)　Power BI Desktop のインストール」を参照してください。

<details>
<summary>　クリックして詳細表示</summary>

> 1. 事前準備でダウンロードしたPBITファイルをダブルクリックし、Power BI Desktop で開きます。  
> 
> |<img src="images/Open_Template_File_1.jpg" width="600">|
> |---------|

</details>

### 2. パラメータの設定とデータソースの設定

テンプレートを設定しデータソースに接続できるようにします。

<details>
<summary>　クリックして詳細表示</summary>

> 1. PBITファイルを開くと、以下のパラメータ設定を求められます。以下の情報を入力してください。
> 
> | パラメータ | 設定値 |
> |---------|---------|
> |SiteUrl| [環境構築手順　9. 動作確認](/README.md#9-%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D) に記載されているサイトURL |
> |SchoolYearRange|3|
> 
> - **SiteUrl**：データソースファイルが格納されているSharePoint Online サイトのURLを入力します。  
> - **SchoolYearRange**：取得するデータ期間の年度数を1以上の整数で入力します。  
>  ※ここでは「SchoolYearRange」を既定の 3 に設定します。   
>  ※本システム運用開始時点では、開始日より約26日前のデータから読み込まれます。
> 
> |<img src="images/Setup_Parameters_1.jpg" width="600">|
> |---------|
> 
> 2. データソースの資格情報設定を求められます。 [Microsoft アカウント] > [サインイン] をクリックし、サインインします。
> 
> |<img src="images/Setup_Parameters_2.jpg" width="600">|
> |---------|
> |<img src="images/Setup_Parameters_3.jpg" width="600">|
> |<img src="images/Setup_Parameters_4.jpg" width="600">|
> 
> 3. サインインが完了したら、 [接続] をクリックします。
> 
> |<img src="images/Setup_Parameters_5.jpg" width="600">|
> |---------|
> 
> 4. 数分待つとレポート画面が表示されます。  
> 
> |<img src="images/Setup_Parameters_6.jpg" width="600">|
> |---------|

</details>

### 3. レポートの保存

レポートを保存します。

<details>
<summary>　クリックして詳細表示</summary>

> 1. [ファイル] タブをクリックします。
> 
> |<img src="images/Save_Report_1.jpg" width="600">|
> |---------|
> 
> 2.  [名前を付けて保存] > [このデバイスを参照する] をクリックします。
> 
> |<img src="images/Save_Report_2.jpg" width="600">|
> |---------|
> 
> 3.  ファイル名を入力し、適当な保存場所を選択して [保存] をクリックします。
> 
> | 設定項目 | 設定値 |
> |---------|---------|
> |ファイル名|01_テナント全体の端末利用状況レポート|
> |ファイルの種類|Power BI ファイル (*.pbix)|
> 
> |<img src="images/Save_Report_3.jpg" width="600">|
> |---------|

</details>

### 4. マイワークスペースへの発行

ブラウザでレポートを閲覧するために、Power BI サービスのマイワークスペースにレポートを発行します。  

<details>
<summary>　クリックして詳細表示</summary>

> 1. [ホーム] タブから [発行] をクリックします。
> 
> |<img src="images/Publish_Report_1.jpg" width="600">|
> |---------|
> 
> 2. 「マイワークスペース」を選択し、 [選択] をクリックして発行を開始します。
> 
> |<img src="images/Publish_Report_2.jpg" width="600">|
> |---------|
> 
> 3. 発行が完了したら、 [Power BI で '01_テナント全体の端末利用状況レポート' を開く] をクリックします。
> 
> |<img src="images/Publish_Report_3.jpg" width="600">|
> |---------|
> 
> 4. ブラウザが立ち上がり、Power BI サービスでレポートが開かれることを確認します。
> 
> |<img src="images/Publish_Report_4.jpg" width="600">|
> |---------|

</details>

### 5. データソース資格情報の設定

マイワークスペースに発行後、Power BI サービスからデータを更新するために資格情報を設定する必要があります。  
以下の手順に従って設定してください。

<details>
<summary>　クリックして詳細表示</summary>

> 1. Power BI サービスの左側メニューから [マイワークスペース] を選択します。
> 
> |<img src="images/Configure_DataSource_Credentials_1.jpg" width="600">|
> |---------|
> 
> 2. 発行したセマンティックモデルの [・・・] > [設定] をクリックし、設定画面を開きます。
> 
> |<img src="images/Configure_DataSource_Credentials_2.jpg" width="600">|
> |---------|
> 
> 3. [データソースの資格情報] セクションの [資格情報を編集] をクリックします。
> 
> |<img src="images/Configure_DataSource_Credentials_3.jpg" width="600">|
> |---------|
> 
> 4. 設定項目を以下に設定し [サインイン] をクリックします。
> 
> | 設定項目 | 設定値 |
> |---------|---------|
> |認証方法|OAuth2|
> |このデータ ソースのプライバシー レベルの設定|Private|
> 
> |<img src="images/Configure_DataSource_Credentials_4.jpg" width="600">|
> |---------|
> 
> 5. 自身のアカウントをクリックします。
> 
> |<img src="images/Configure_DataSource_Credentials_5.jpg" width="600">|
> |---------|
> 
> 6. 資格情報が設定されます。次の手順で引き続き設定を行うため、設定画面はそのまま開いておきます。
> 
> |<img src="images/Configure_DataSource_Credentials_6.jpg" width="600">|
> |---------|

</details>

### 6. データの自動更新設定

レポートで最新の情報を確認するためにデータの自動更新を設定する必要があります。  
以下の手順に従って設定してください。

> [!NOTE]
> + 環境構築で設定された最新データを取得するタイミングに合わせたスケジュール設定になります。

<details>
<summary>　クリックして詳細表示</summary>

> 1. （前の手順に引き続き、）セマンティックモデルの設定画面を開きます。
> 2. [最新の情報に更新] セクションからスケジュール設定を行います。設定値は以下を参照してください。
> 
> | 設定項目 | 設定値 |
> |---------|---------|
> |タイムゾーン|(UTC+09:00)大阪、札幌、東京|
> |情報更新スケジュールの構成|オン|
> |更新の頻度|毎日|
> |時刻|12:00PM|
> 
> |<img src="images/Configure_Scheduled_Refresh_1.jpg" width="600">|
> |---------|
> 
> 3. [適用] をクリックして、設定を保存します。
> 
> |<img src="images/Configure_Scheduled_Refresh_2.jpg" width="600">|
> |---------|

</details>

### 7. データ取得の動作確認

Power BI サービスでデータの手動更新を行い、データ取得の動作確認を実施します。  

<details>
<summary>　クリックして詳細表示</summary>

> 1. マイワークスペースを開きます。
> 
> |<img src="images/Refresh_SemanticModel_1.jpg" width="600">|
> |---------|
> 
> 2. データソースの資格情報を設定したセマンティックモデルを選択し、更新マーク（🔄）をクリックします。
> 
> |<img src="images/Refresh_SemanticModel_2.jpg" width="600">|
> |---------|
> 
> 4. 「最新の情報に更新済み」の日時が更新されたら完了です。  
>    ※本システムの運用開始時点の場合は数分で完了します。1年度分のデータが蓄積されている場合は5~10分ほどかかります。
> 
> |<img src="images/Refresh_SemanticModel_3.jpg" width="600">|
> |---------|

</details>

## 📃レポートの閲覧方法

### 1. レポートの閲覧

Power BI サービスのマイワークスペースからレポートを開いて閲覧します。

<details>
<summary>　クリックして詳細表示</summary>

> 1. [https://app.powerbi.com/](https://app.powerbi.com/) にアクセスしてPower BI サービスを開きます。
> 2. Power BI サービスの左側メニューから [マイワークスペース] を選択します。
> 
> |<img src="images/View_Report_1.jpg" width="600">|
> |---------|
> 
> 3. 「01_テナント全体の端末利用状況レポート」という名前のレポートをクリックします。
> 
> |<img src="images/View_Report_2.jpg" width="600">|
> |---------|
> 
> 4. レポートが開かれます。
> 
> |<img src="images/View_Report_3.jpg" width="600">|
> |---------|
> 

</details>

## 🔄 取得データ期間の変更方法

### 1. パラメータの変更

マイワークスペースに発行後、取得するデータ期間の年度数を変更する場合は、以下の手順に従って設定してください。

> [!NOTE]
> + データ期間の年度数は「3」を推奨値としています。
> + データ量が増えるとデータ更新やレポート画面の描写に時間がかかります。また、性能上限に達した場合はエラーとなります。

<details>
<summary>　クリックして詳細表示</summary>

> 1. Power BI サービスの左側メニューから [マイワークスペース] を選択します。
> 
> |<img src="images/Configure_Parameters_1.jpg" width="600">|
> |---------|
> 
> 2. セマンティックモデルの [・・・] > [設定] をクリックし、設定画面を開きます。
> 
> |<img src="images/Configure_Parameters_2.jpg" width="600">|
> |---------|
> 
> 3. [パラメーター] セクションから SchoolYearRange を任意の値に変更します。  
> 
> |<img src="images/Configure_Parameters_3.jpg" width="600">|
> |---------|
> 
> 4. 適用して設定を保存します。
> 
> |<img src="images/Configure_Parameters_4.jpg" width="600">|
> |---------|
> 
> 5. 変更後のパラメータでデータを取得する場合は、上述の「利用開始手順 7. データ取得の動作確認」を実施してください。

</details>

## ⚠ 注意事項

> [!CAUTION]
> + データを取り込んだレポートファイル (.pbix) は第三者に共有しないで下さい。含まれる情報が意図せず閲覧されてしまいます。

## 📚 関連情報

本プロジェクトに関連するドキュメント

- [Power BI Desktop のインストールガイド（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop)
- [Power BI Desktop の起動に関する問題を解決する - Power BI | Microsoft Learn<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/connect-data/desktop-error-launching-desktop)

[Back to top](#top)
